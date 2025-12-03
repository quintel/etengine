# frozen_string_literal: true

module ScenarioPacker
  module Contracts
    # Validator for scenario collections
    module ScenarioCollectionValidator
      extend Dry::Monads[:result]

      def self.validate_existence(ids)
        return Failure('no IDs provided') if ids.nil? || ids.empty?

        scenarios = Scenario.where(id: ids)

        if scenarios.empty?
          Failure("no scenarios found with IDs: #{ids.join(', ')}")
        else
          Success(scenarios)
        end
      end

      def self.validate_with_ability(ids, ability)
        return Failure('no IDs provided') if ids.nil? || ids.empty?

        scenarios = Scenario.accessible_by(ability).where(id: ids)

        if scenarios.empty?
          Failure("no accessible scenarios found with IDs: #{ids.join(', ')}")
        else
          Success(scenarios)
        end
      end
    end
  end
end
