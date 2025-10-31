# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Extracts and coerces user_values from scenario data.
    class ParseProvidedValues
      include Dry::Monads[:result]

      def call(scenario, scenario_data)
        values = scenario_data[:user_values] || {}

        provided_values = values.each_with_object({}) do |(key, value), collection|
          collection[key.to_s] = coerce_provided_value(scenario, key, value)
        end

        Success(provided_values)
      end

      private

      def coerce_provided_value(scenario, key, value)
        input = Input.get(key)

        if input.nil?
          nil
        elsif value == 'reset'
          value_from_parent(scenario, key) || :reset
        else
          input.coerce(value)
        end
      end

      def value_from_parent(scenario, key)
        parent = scenario.parent
        return nil unless parent

        parent.user_values[key] ||
          (parent.respond_to?(:balanced_values) && parent.balanced_values[key])
      end
    end
  end
end
