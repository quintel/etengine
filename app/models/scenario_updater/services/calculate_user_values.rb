# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Calculates the final user_values hash by merging base values with provided values.
    # Handles reset logic and coupling exclusions.
    class CalculateUserValues
      include Dry::Monads[:result]

      def call(scenario, provided_values, uncoupled_inputs, reset)
        base_values = base_user_values(scenario, provided_values, uncoupled_inputs, reset)
        user_values = base_values.dup

        # Apply provided values (including resets)
        provided_values.each do |key, value|
          value == :reset ? user_values.delete(key) : user_values[key] = value
        end

        Success(user_values)
      end

      private

      def base_user_values(scenario, provided_values, uncoupled_inputs, reset)
        if reset
          if scenario.parent
            scenario.parent.user_values.merge(provided_values)
          else
            provided_values.dup
          end
        else
          # Remove uncoupled inputs from base
          scenario.user_values.except(*uncoupled_inputs)
        end
      end
    end
  end
end
