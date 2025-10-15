# frozen_string_literal: true

class ScenarioUpdater
  module Inputs
    # Calculates balanced values for input groups to ensure they sum to 100%.
    class Balancer < Base
      def initialize(scenario, params, current_user, user_values, provided_values, couplings_manager: nil)
        super(scenario, params, current_user)
        @user_values = user_values
        @provided_values = provided_values
        @couplings_manager = couplings_manager
      end

      def calculate_balanced_values
        return {} if @user_values.blank?

        balanced = base_balanced_values

        # Remove balanced values for groups being updated
        each_group(@provided_values) do |_, inputs|
          inputs.each { |input| balanced.delete(input.key) }
        end

        if should_autobalance?
          each_group(@provided_values) do |_, inputs|
            if (balanced_group = balance_group(inputs))
              balanced.merge!(balanced_group)
            end
          end
        end

        balanced
      end

      private

      def should_autobalance?
        params[:autobalance] != 'false' && params[:autobalance] != false
      end

      def balance_group(inputs)
        if params[:force_balance]
          inputs.each do |input|
            @user_values.delete(input.key) unless @provided_values.key?(input.key)
          end
          ::Balancer.new(inputs).balance(scenario, @provided_values)
        else
          ::Balancer.new(inputs).balance(scenario, @user_values)
        end
      rescue ::Balancer::BalancerError
        nil
      end

      def base_balanced_values
        if params[:reset]
          scenario.parent&.balanced_values || {}
        else
          couplings_manager.uncoupled_base_balanced_values(scenario.balanced_values || {})
        end
      end

      def couplings_manager
        @couplings_manager ||= CouplingsManager.new(scenario, params, current_user)
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
    end
  end
end
