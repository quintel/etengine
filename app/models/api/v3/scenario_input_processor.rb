# frozen_string_literal: true

module Api
  module V3
    class ScenarioInputProcessor
      TRUTHY_VALUES = Set.new([true, 'true', '1']).freeze
      FALSEY_VALUES = Set.new([false, 'false', '0']).freeze

      def initialize(scenario_data, scenario, provided_values, parent_values, uncoupled_sliders, autobalance: true, force_balance: false)
        @scenario_data = scenario_data
        @scenario = scenario
        @provided_values = provided_values
        @parent_values = parent_values
        @uncoupled_sliders = uncoupled_sliders
        @autobalance = autobalance
        @force_balance = force_balance
      end

      def balanced_values
        @balanced_values ||= calculate_balanced_values
      end

      def user_values
        @user_values ||= calculate_user_values
      end

      private

      def calculate_balanced_values
        return {} if user_values.blank?

        balanced = base_balanced_values

        each_group(@provided_values) do |_, inputs|
          inputs.each { |input| balanced.delete(input.key) }
        end

        if @autobalance
          each_group(@provided_values) do |_, inputs|
            if (balanced_group = balance_group(inputs))
              balanced.merge!(balanced_group)
            end
          end
        end

        balanced
      end

      def calculate_user_values
        values = base_user_values

        @provided_values.each do |key, value|
          value == :reset ? values.delete(key) : values[key] = value
        end

        values
      end

      def base_user_values
        if reset?
          @parent_values.merge(@provided_values)
        else
          uncoupled_base_user_values
        end
      end

      def base_balanced_values
        if reset?
          @scenario.parent&.balanced_values || {}
        else
          uncoupled_base_balanced_values
        end
      end

      def uncoupled_base_user_values
        values = @scenario.user_values.dup

        if uncouple?
          values.except!(*@uncoupled_sliders)
        else
          values
        end
      end

      def uncoupled_base_balanced_values
        values = (@scenario.balanced_values || {}).dup

        if uncouple?
          values.except!(*@uncoupled_sliders)
        else
          values
        end
      end

      def balance_group(inputs)
        if @force_balance
          inputs.each do |input|
            user_values.delete(input.key) unless @provided_values.key?(input.key)
          end

          Balancer.new(inputs).balance(@scenario, @provided_values)
        else
          Balancer.new(inputs).balance(@scenario, user_values)
        end
      rescue Balancer::BalancerError
        nil
      end

      def each_group(values)
        group_names = values.map do |key, _|
          (input = Input.get(key)) && input.share_group.presence || nil
        end.compact.uniq

        group_names.each do |name|
          yield name, Input.in_share_group(name)
        end

        nil
      end

      def reset?
        @scenario_data[:reset]
      end

      def uncouple?
        @scenario_data[:uncouple]
      end
    end
  end
end
