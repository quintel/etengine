# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Calculates balanced values for input share groups to ensure they sum to 100%.
    class CalculateBalancedValues
      include Dry::Monads[:result]

      def call(scenario, user_values:, provided_values:, uncoupled_inputs:, reset: false, autobalance: true, force_balance: false)
        return Success({}) if user_values.blank?

        balanced = base_balanced_values(scenario, uncoupled_inputs, reset)

        # Remove balanced values for groups being updated
        ShareGroups.each(provided_values) do |_, inputs|
          inputs.each { |input| balanced.delete(input.key) }
        end

        balance_groups(scenario, provided_values, user_values, autobalance, force_balance, balanced) if autobalance

        Success(balanced)
      end

      private

      def balance_groups(scenario, provided_values, user_values, autobalance, force_balance, balanced)
        ShareGroups.each(provided_values) do |_, inputs|
          if (balanced_group = balance_group(scenario, inputs, user_values, provided_values, force_balance))
            balanced.merge!(balanced_group)
          end
        end
      end

      def balance_group(scenario, inputs, user_values, provided_values, force_balance)
        if force_balance
          values_to_balance = user_values.dup
          inputs.each do |input|
            values_to_balance.delete(input.key) unless provided_values.key?(input.key)
          end
          ::Balancer.new(inputs).balance(scenario, provided_values)
        else
          ::Balancer.new(inputs).balance(scenario, user_values)
        end
      rescue ::Balancer::BalancerError
        nil
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
