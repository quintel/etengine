# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Calculates balanced values for input share groups to ensure they sum to 100%.
    #
    # Balancing errors are swallowed here: the balancer computes, and
    # ValidateBalance judges and reports, so exactly one service owns
    # share-group error messages.
    class CalculateBalancedValues
      include Dry::Monads[:result]

      def call(scenario, user_values:, provided_values:, uncoupled_inputs:, reset: false, autobalance: true, force_balance: false)
        return Success(user_values:, balanced_values: {}) if user_values.blank?

        user_values = user_values.dup
        balanced    = base_balanced_values(scenario, uncoupled_inputs, reset)

        ShareGroups.each(provided_values) do |_, inputs|
          # Remove balanced values for groups being updated.
          inputs.each { |input| balanced.delete(input.key) }

          corrections = balance_group(
            scenario, inputs, user_values, provided_values, autobalance, force_balance
          )

          apply_corrections(corrections, user_values, balanced)
        end

        Success(user_values:, balanced_values: balanced)
      end

      private

      # Corrections for keys the user set land in user_values; everything else
      # is a balanced value.
      def apply_corrections(corrections, user_values, balanced)
        corrections.each do |key, value|
          if user_values.key?(key)
            user_values[key] = value
          else
            balanced[key] = value
          end
        end
      end

      def balance_group(scenario, inputs, user_values, provided_values, autobalance, force_balance)
        values = force_balance ? provided_values : user_values
        ::Balancer.new(inputs).balance(scenario, values, autobalance:)
      rescue ::Balancer::BalancerError
        {}
      end

      def base_balanced_values(scenario, uncoupled_inputs, reset)
        if reset
          scenario.parent&.balanced_values || {}
        else
          # Remove uncoupled inputs from balanced values
          (scenario.balanced_values || {}).except(*uncoupled_inputs)
        end
      end
    end
  end
end
