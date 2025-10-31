# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Validates scenario model (ActiveRecord)
    class PersistScenario
      include Dry::Monads[:result]

      def call(scenario, attributes, skip_validation = false)
        scenario.attributes = attributes

        unless skip_validation
          # Only validate if we haven't skipped input validation
          unless scenario.valid?
            errors = scenario.errors.full_messages.map { |msg| "Scenario: #{msg}" }
            return Failure(errors)
          end
        end

        if scenario.save(validate: false)
          Success(scenario)
        else
          Failure(['Failed to save scenario'])
        end
      end
    end
  end
end
