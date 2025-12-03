# frozen_string_literal: true

module ScenarioPacker
  class Dump
    include Dry::Monads[:result]

    # Creates a new Scenario API dumper.
    #
    # @param [Scenario] scenario
    #   The scenarios for which we want JSON.
    #
    def initialize(scenario)
      @scenario = scenario
    end

    # Dumps the scenario to a hash with validation.
    #
    # @return [Dry::Monads::Result]
    #   Success with hash or Failure with error message.
    #
    def call
      validate_scenario
        .bind { |_| build_json }
        .bind { |json| add_sortables(json) }
        .bind { |json| add_curves(json) }
    end

    private

    def validate_scenario
      return Failure('scenario is required') if @scenario.nil?
      return Failure('scenario must be persisted') unless @scenario.persisted?

      Success(@scenario)
    end

    def build_json
      json = @scenario.as_json(
        only: %i[
          area_code end_year private keep_compatible
          user_values balanced_values active_couplings
          user_curves
        ]
      )
      Success(json)
    rescue StandardError => e
      Failure("Failed to build JSON: #{e.message}")
    end

    def add_sortables(json)
      json[:user_sortables] = @scenario.serialize_sortables

      Success(json)
    rescue StandardError => e
      Failure("Failed to add sortables: #{e.message}")
    end

    def add_curves(json)
      json[:user_curves] = @scenario.serialize_curves

      Success(json)
    rescue StandardError => e
      Failure("Failed to add curves: #{e.message}")
    end
  end
end
