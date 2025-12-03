# frozen_string_literal: true

module ScenarioPacker
  class DumpCollection
    extend Dry::Monads[:result]
    include Dry::Monads[:result]

    class InvalidParamsError < StandardError; end

    attr_reader :dump_type, :user_name

    # Build DumpCollection from params and user context.
    # @param params [Hash] request parameters
    # @param user   [User] current_user for user-specific dumps
    # @return [Dry::Monads::Result]
    def self.from_params(params, user)
      dump_type = extract_dump_type(params)

      build_packer(dump_type, params, user)
        .fmap { |packer| tag_packer(packer, dump_type, user) }
    end

    # Instantiate a collection by an explicit list of IDs.
    # @param ids [Array<Integer>] scenario IDs
    # @return [Dry::Monads::Result]
    def self.from_ids(ids)
      scenarios = Scenario.where(id: ids)

      if scenarios.any?
        Success(new(scenarios))
      else
        Failure("No scenarios found with IDs: #{ids.join(', ')}")
      end
    end

    # Instantiate a collection from an ActiveRecord::Relation scope
    # @param scope [ActiveRecord::Relation] scenarios scope
    # @return [Dry::Monads::Result]
    def self.from_scope(scope)
      if scope.any?
        Success(new(scope))
      else
        Failure('No scenarios found matching criteria')
      end
    end

    # Determine dump_type from params (defaults to 'ids')
    def self.extract_dump_type(params)
      (params[:dump_type].to_s.presence || 'ids')
    end

    # Dispatch to the correct builder based on type
    def self.build_packer(type, params, user)
      case type
      when 'ids'
        build_from_ids(params[:scenario_ids])
      when 'featured'
        build_featured
      when 'my_scenarios'
        build_my_scenarios(user)
      else
        Failure("Unknown dump type: #{type.inspect}")
      end
    end

    # Parse and validate ID list, then delegate to from_ids
    def self.build_from_ids(raw_ids)
      contract = Contracts::IdsContract.new
      result = contract.call(ids: raw_ids)

      if result.success?
        from_ids(result.to_h[:parsed_ids])
      else
        Failure(result.errors.to_h)
      end
    end

    # Build packer for featured scenarios with metadata
    def self.build_featured
      featured_scenarios = ::MyEtm::FeaturedScenario.cached_scenarios
      ids = featured_scenarios.map(&:id)

      from_ids(ids).fmap do |packer|
        # Store the featured scenario metadata for use in dumps
        packer.instance_variable_set(:@title_metadata, featured_scenarios)
        packer
      end
    end

    # Build packer for current user's recent scenarios
    def self.build_my_scenarios(user)
      return Failure('User is required') unless user

      scope = user.scenarios.where('scenarios.updated_at >= ?', 1.month.ago)
      from_scope(scope)
    end

    # Tag instance with type and user info for filename logic
    def self.tag_packer(packer, type, user)
      packer.instance_variable_set(:@dump_type, type)
      packer.instance_variable_set(:@user_name, user.name) if user
      packer
    end

    # Initialize with a collection of Scenario records
    # @param scope [ActiveRecord::Relation] scenarios to dump
    def initialize(scope)
      @scope         = scope
      @ids           = scope.pluck(:id)
      @records_by_id = scope.index_by(&:id)
      @dump_type     = 'ids'
      @user_name     = nil
      @title_metadata = nil
    end

    # Build array of JSON-ready hashes, preserving original ID order
    # @return [Dry::Monads::Result]
    def call
      results = @ids.map do |id|
        rec = @records_by_id[id]
        next Success(nil) unless rec

        Dump.new(rec).call.fmap do |dump_json|
          add_title_metadata(dump_json, id)
        end
      end

      # Collect all results, fail if any failed
      failures = results.select(&:failure?)
      return Failure(failures.map(&:failure)) if failures.any?

      # Extract successful values, filtering out nils
      Success(results.map(&:value!).compact)
    end

    # Generate pretty-printed JSON string of the entire collection.
    # @return [Dry::Monads::Result]
    def to_json
      call.fmap { |json_array| JSON.pretty_generate(json_array) }
    end

    private

    def add_title_metadata(dump_json, id)
      # Add Title to metadata if available
      if @title_metadata
        scenario = @title_metadata.find { |fs| fs.id == id }
        if scenario && scenario.title
          dump_json['metadata'] ||= {}
          dump_json['metadata']['title'] = scenario.title
        end
      end

      dump_json
    end

    public

    # Determine filename based on dump type
    # @return [String]
    def filename
      date_suffix = Time.current.strftime('%d-%m-%y')
      environment_map = {
        'production' => 'pro',
        'development' => 'local',
        'staging' => 'beta'
      }

      environment = environment_map[Rails.env.to_s] || Rails.env.to_s.downcase

      base_name = case dump_type
                  when 'featured'
                    'featured'
                  when 'my_scenarios'
                    name = user_name.to_s.parameterize.presence || 'user'
                    "#{name}"
                  else
                    "#{@ids.join('-')}"
                  end

      "#{base_name}_#{environment}_#{date_suffix}.json"
    end
  end
end
