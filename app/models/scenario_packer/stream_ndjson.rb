# frozen_string_literal: true

# Provides the requested scenarios in NDJSON line batches as a stream.
module ScenarioPacker
  class StreamNdjson
    include Dry::Monads[:result]

    SCENARIO_METHODS = %i[start_year inactive_couplings].freeze
    SCENARIO_ATTRIBUTES = %i[
      id area_code end_year source private keep_compatible
      created_at updated_at user_values balanced_values metadata
      active_couplings
    ].freeze

    def initialize(params, ability, scenarios = nil)
      @params = params
      @ability = ability
      @scenarios = scenarios
    end

    # Validates input and returns a new StreamNdjson instance with scenarios loaded
    def call
      return Success(self) if @scenarios

      validate_and_find_scenarios
        .fmap { |scenarios| self.class.new(@params, @ability, scenarios) }
    end

    # Enumerable-style iteration: yields one hash per scenario.
    def each
      return enum_for(:each) unless block_given?

      raise 'Cannot iterate without scenarios. Call #call first.' unless @scenarios

      @scenarios.each do |scenario|
        yield ndjson_line(scenario)
      end
    end

    private

    def validate_and_find_scenarios
      return Failure('ability is required') unless @ability

      ids = Array(@params[:ids])
      Contracts::ScenarioCollectionValidator
        .validate_with_ability(ids, @ability)
    end

    def find_scenarios(ability, ids)
      return [] if ids.blank?

      Scenario.accessible_by(ability).where(id: ids)
    end

    def ndjson_line(scenario)
      json = scenario.as_json(only: SCENARIO_ATTRIBUTES, methods: SCENARIO_METHODS).symbolize_keys
      json[:user_sortables] = scenario.serialize_sortables
      json[:user_curves] = scenario.serialize_curves
      extract_metadata(json)
    end

    def extract_metadata(json)
      json[:metadata] = {
        id: json[:id],
       source: json[:source],
       created_at: json[:created_at],
       updated_at: json[:updated_at]
      }

      # Remove the moved fields from the main JSON
      json.except(:id, :source, :created_at, :updated_at)
    end
  end
end
