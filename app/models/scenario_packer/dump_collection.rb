# frozen_string_literal: true

module ScenarioPacker
  class DumpCollection
    class InvalidParamsError < StandardError; end

    attr_reader :dump_type, :user_name

    # Build DumpCollection from params and user context.
    # @param params [Hash] request parameters
    # @param user   [User] current_user for user-specific dumps
    # @return [DumpCollection]
    def self.from_params(params, user)
      dump_type = extract_dump_type(params)
      packer    = build_packer(dump_type, params, user)
      tag_packer(packer, dump_type, user)
    end

    # Instantiate a collection by an explicit list of IDs.
    # @param ids [Array<Integer>] scenario IDs
    # @return [DumpCollection]
    def self.from_ids(ids)
      new(Scenario.where(id: ids))
    end

    # Instantiate a collection from an ActiveRecord::Relation scope
    # @param scope [ActiveRecord::Relation] scenarios scope
    # @return [DumpCollection]
    def self.from_scope(scope)
      new(scope)
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
        raise InvalidParamsError, "Unknown dump type: #{type.inspect}"
      end
    end

    # Parse and validate ID list, then delegate to from_ids
    def self.build_from_ids(raw_ids)
      ids = parse_ids(raw_ids)
      raise InvalidParamsError, 'Please enter at least one scenario ID.' if ids.empty?

      from_ids(ids)
    end

    # Build packer for featured scenarios with metadata
    def self.build_featured
      featured_scenarios = ::MyEtm::FeaturedScenario.cached_scenarios
      ids = featured_scenarios.map(&:id)

      packer = from_ids(ids)
      # Store the featured scenario metadata for use in dumps
      packer.instance_variable_set(:@title_metadata, featured_scenarios)
      packer
    end

    # Build packer for current user's recent scenarios
    def self.build_my_scenarios(user)
      scope = user.scenarios.where('scenarios.updated_at >= ?', 1.month.ago)
      from_scope(scope)
    end

    # Tag instance with type and user info for filename logic
    def self.tag_packer(packer, type, user)
      packer.instance_variable_set(:@dump_type, type)
      packer.instance_variable_set(:@user_name, user.name) if user
      packer
    end

    # Convert comma-separated ID string into unique integer array
    # @param raw [String,Array] raw input representing IDs
    # @return [Array<Integer>]
    def self.parse_ids(raw)
      Array(raw.to_s)
        .flat_map { |s| s.split(/\s*,\s*/) }
        .map(&:to_i)
        .reject(&:zero?)
        .uniq
    end
    private_class_method :parse_ids

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
    # @return [Array<Hash>]
    def as_json(*)
      @ids.filter_map do |id|
        rec = @records_by_id[id]
        next unless rec

        dump_json = Dump.new(rec).as_json

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
    end

    # Generate pretty-printed JSON string of the entire collection.
    # @return [String]
    def to_json(*)
      JSON.pretty_generate(as_json(*))
    end

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
