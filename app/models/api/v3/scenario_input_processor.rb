module Api
  module V3
    class ScenarioInputProcessor
      attr_reader :user_values, :balanced_values, :provided_values, :provided_values_without_resets

      def initialize(scenario_data, scenario, data, current_user)
        @scenario_data = scenario_data
        @scenario = scenario
        @data = data
        @current_user = current_user

        @provided_values = extract_provided_values
        @provided_values_without_resets = extract_provided_values_without_resets
        @user_values = extract_user_values
        @balanced_values = calculate_balanced_values
      end

      private

      def extract_provided_values
        values = @scenario_data[:user_values] || {}
        values.each_with_object({}) do |(key, value), collection|
          collection[key.to_s] = coerce_provided_value(key, value)
        end
      end

      def extract_provided_values_without_resets
        provided_values.reject { |_, value| value == :reset }
      end

      def extract_user_values
        values = base_user_values
        provided_values.each do |key, value|
          value == :reset ? values.delete(key) : values[key] = value
        end
        values
      end

      def calculate_balanced_values
        return {} if user_values.blank?

        balanced = base_balanced_values
        ScenarioValidator.each_group(@scenario, provided_values) do |_, inputs|
          inputs.each { |input| balanced.delete(input.key) }
        end

        if @data[:autobalance] != 'false' && @data[:autobalance] != false
          ScenarioValidator.each_group(@scenario, provided_values) do |_, inputs|
            if (balanced_group = balance_group(inputs))
              balanced.merge!(balanced_group)
            end
          end
        end

        balanced
      end

      def base_user_values
        if reset?
          @scenario.parent ? @scenario.parent.user_values.merge(provided_values) : provided_values.dup
        else
          uncoupled_base_user_values
        end
      end

      def base_balanced_values
        reset? ? (@scenario.parent&.balanced_values || {}) : uncoupled_base_balanced_values
      end

      def uncoupled_base_user_values
        values = @scenario.user_values.dup
        uncouple? ? values.except!(*@scenario.coupled_sliders) : values
      end

      def uncoupled_base_balanced_values
        values = (@scenario.balanced_values || {}).dup
        uncouple? ? values.except!(*@scenario.coupled_sliders) : values
      end

      def balance_group(inputs)
        Balancer.new(inputs).balance(@scenario, @data[:force_balance] ? provided_values : user_values)
      rescue Balancer::BalancerError
        nil
      end

      def coerce_provided_value(key, value)
        input = Input.get(key)
        return nil if input.nil?
        return value_from_parent(key) || :reset if value == 'reset'

        input.coerce(value)
      end

      def value_from_parent(key)
        parent = @scenario.parent
        parent ? (parent.user_values[key] || (parent.respond_to?(:balanced_values) && parent.balanced_values[key])) : nil
      end

      def reset?
        @data.fetch(:reset, false)
      end

      def uncouple?
        ScenarioValidator::FALSEY_VALUES.include?(@data.fetch(:coupling, true))
      end
    end
  end
end
