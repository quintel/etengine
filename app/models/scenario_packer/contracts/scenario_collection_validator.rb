# frozen_string_literal: true

module ScenarioPacker
  module Contracts
    # Validator for scenario collections
    module ScenarioCollectionValidator
      extend Dry::Monads[:result]

      SCENARIO_INCLUDES = %i[
        user_curves
        heat_network_orders
        forecast_storage_order
        hydrogen_supply_order
        hydrogen_demand_order
        households_space_heating_producer_order
      ].freeze

      def self.validate_existence(ids)
        validate_scenarios(ids, Scenario.all, 'no scenarios found')
      end

      def self.validate_with_ability(ids, ability)
        validate_scenarios(ids, Scenario.accessible_by(ability), 'no accessible scenarios found')
      end

      def self.validate_scenarios(ids, scope, error_prefix)
        return Failure('no IDs provided') if ids.blank?

        scenarios = scope.where(id: ids).includes(*SCENARIO_INCLUDES)

        if scenarios.empty?
          Failure("#{error_prefix} with IDs: #{ids.join(', ')}")
        else
          Success(scenarios)
        end
      end

      private_class_method :validate_scenarios
    end
  end
end
