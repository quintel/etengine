# frozen_string_literal: true

module Api
  module V3
    class ScenarioInputProcessor

      TRUTHY_VALUES = Set.new([true, 'true', '1']).freeze
      FALSEY_VALUES = Set.new([false, 'false', '0']).freeze

      def initialize(scenario_data, scenario_updater)
        @scenario_data = scenario_data
        @scenario_updater = scenario_updater
      end

      def balanced_values
        @balanced_values ||= calculate_balanced_values
      end

      def user_values
        @user_values ||= calculate_user_values
      end

      private

      def calculate_balanced_values
        if user_values.blank?
          {}
        else
          balanced = base_balanced_values

          @scenario_updater.each_group(@scenario_updater.provided_values) do |_, inputs|
            inputs.each { |input| balanced.delete(input.key) }
          end

          if @scenario_data[:autobalance] != 'false' && @scenario_data[:autobalance] != false
            @scenario_updater.each_group(@scenario_updater.provided_values) do |_, inputs|
              if (balanced_group = balance_group(inputs))
                balanced.merge!(balanced_group)
              end
            end
          end

          balanced
        end
      end

      def calculate_user_values
        values = base_user_values

        @scenario_updater.provided_values.each do |key, value|
          value == :reset ? values.delete(key) : values[key] = value
        end

        values
      end

      def base_user_values
        if @scenario_updater.reset?
          if @scenario_updater.scenario.parent
            @scenario_updater.scenario.parent.user_values.merge(@scenario_updater.provided_values)
          else
            @scenario_updater.provided_values.dup
          end
        else
          uncoupled_base_user_values
        end
      end

      def base_balanced_values
        if @scenario_updater.reset?
          @scenario_updater.scenario.parent&.balanced_values || {}
        else
          uncoupled_base_balanced_values
        end
      end

      def uncoupled_base_user_values
        values = @scenario_updater.scenario.user_values.dup

        if @scenario_updater.uncouple?
          values.except!(*@scenario_updater.scenario.coupled_sliders)
        else
          values
        end
      end

      def uncoupled_base_balanced_values
        values = (@scenario_updater.scenario.balanced_values || {}).dup

        if @scenario_updater.uncouple?
          values.except!(*@scenario_updater.scenario.coupled_sliders)
        else
          values
        end
      end

      def balance_group(inputs)
        if @scenario_data[:force_balance]
          inputs.each do |input|
            user_values.delete(input.key) unless @scenario_updater.provided_values.key?(input.key)
          end

          Balancer.new(inputs).balance(@scenario_updater.scenario, @scenario_updater.provided_values)
        else
          Balancer.new(inputs).balance(@scenario_updater.scenario, user_values)
        end
      rescue Balancer::BalancerError
        nil
      end
    end
  end
end
