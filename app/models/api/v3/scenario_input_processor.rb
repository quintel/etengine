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

      # Extracts the provided values from the scenario data.
      # @return [Hash]
      def extract_provided_values
        values = @scenario_data[:user_values] || {}
        values.each_with_object({}) do |(key, value), collection|
          collection[key.to_s] = coerce_provided_value(key, value)
        end
      end

      # Extracts the provided values excluding those to be reset.
      # @return [Hash]
      def extract_provided_values_without_resets
        provided_values.reject { |_, value| value == :reset }
      end

      # Extracts the user values by merging provided values with base user values.
      # @return [Hash]
      def extract_user_values
        values = base_user_values
        provided_values.each do |key, value|
          value == :reset ? values.delete(key) : values[key] = value
        end
        values
      end

      # Calculates the balanced values required to maintain group balances.
      # @return [Hash]
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

      # Returns the base user values, either reset or uncoupled.
      # @return [Hash]
      def base_user_values
        if reset?
          @scenario.parent ? @scenario.parent.user_values.merge(provided_values) : provided_values.dup
        else
          uncoupled_base_user_values
        end
      end

      # Returns the base balanced values, either reset or uncoupled.
      # @return [Hash]
      def base_balanced_values
        reset? ? (@scenario.parent&.balanced_values || {}) : uncoupled_base_balanced_values
      end

      # Returns the uncoupled base user values.
      # @return [Hash]
      def uncoupled_base_user_values
        values = @scenario.user_values.dup
        uncouple? ? values.except!(*@scenario.coupled_sliders) : values
      end

      # Returns the uncoupled base balanced values.
      # @return [Hash]
      def uncoupled_base_balanced_values
        values = (@scenario.balanced_values || {}).dup
        uncouple? ? values.except!(*@scenario.coupled_sliders) : values
      end

      # Balances a group of inputs.
      # @param [Array<Input>] inputs
      # @return [Hash]
      #   The balanced values for the group.
      def balance_group(inputs)
        Balancer.new(inputs).balance(@scenario, @data[:force_balance] ? provided_values : user_values)
      rescue Balancer::BalancerError
        nil
      end

      # Coerces the provided value into the appropriate type for the input.
      # @return [Object]
      #   The coerced value.
      def coerce_provided_value(key, value)
        input = Input.get(key)
        return nil if input.nil?
        return value_from_parent(key) || :reset if value == 'reset'

        input.coerce(value)
      end

      # Retrieves the value of the input from the parent scenario.
      # @return [Object, nil]
      #   The value from the parent scenario, or nil if not available.
      def value_from_parent(key)
        parent = @scenario.parent
        parent ? (parent.user_values[key] || (parent.respond_to?(:balanced_values) && parent.balanced_values[key])) : nil
      end

      # Determines if the scenario should be reset.
      # @return [Boolean]
      def reset?
        @data.fetch(:reset, false)
      end

      # Determines if the scenario should be uncoupled.
      # @return [Boolean]
      def uncouple?
        ScenarioValidator::FALSEY_VALUES.include?(@data.fetch(:coupling, true))
      end
    end
  end
end
