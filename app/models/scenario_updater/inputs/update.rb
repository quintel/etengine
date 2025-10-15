# frozen_string_literal: true

class ScenarioUpdater
  module Inputs
    # Processes scenario input updates by calculating user values, balanced values,
    # and validating the results. Orchestrates other input validation / manipulation
    # classes in the ScenarioUpdater::Inputs
    class Update < Base
      attr_reader :user_values, :balanced_values

      def initialize(scenario, params, current_user, couplings_manager: nil)
        super(scenario, params, current_user)
        @couplings_manager = couplings_manager
      end

      def process
        calculate_user_values
        calculate_balanced_values
        validate_all
      end

      def valid?
        return @valid if defined?(@valid)

        @valid = @validator.valid? & @balance_validator.valid?
      end

      def errors
        @errors ||= begin
          errs = ActiveModel::Errors.new(self)

          if @validator
            @validator.errors.each do |error|
              errs.add(error.attribute, error.message)
            end
          end

          if @balance_validator
            @balance_validator.errors.each do |error|
              errs.add(error.attribute, error.message)
            end
          end

          errs
        end
      end

      def provided_values_without_resets
        @provided_values_without_resets ||= provided_values.reject { |_, value| value == :reset }
      end

      private

      def calculate_user_values
        @user_values = base_user_values

        provided_values.each do |key, value|
          value == :reset ? @user_values.delete(key) : @user_values[key] = value
        end
      end

      def calculate_balanced_values
        @balancer = Balancer.new(
          scenario,
          params,
          current_user,
          @user_values,
          provided_values,
          couplings_manager: couplings_manager
        )
        @balanced_values = @balancer.calculate_balanced_values
      end

      def validate_all
        @validator = Validator.new(scenario, provided_values_without_resets, current_user)
        @balance_validator = BalanceValidator.new(
          scenario,
          @user_values,
          @balanced_values,
          provided_values
        )
      end

      def provided_values
        @provided_values ||= begin
          scenario_data = (params[:scenario] || {}).with_indifferent_access
          values = scenario_data[:user_values] || {}

          values.each_with_object({}) do |(key, value), collection|
            collection[key.to_s] = coerce_provided_value(key, value)
          end
        end
      end

      def base_user_values
        if params[:reset]
          if scenario.parent
            scenario.parent.user_values.merge(provided_values)
          else
            provided_values.dup
          end
        else
          uncoupled_base_user_values
        end
      end

      def uncoupled_base_user_values
        couplings_manager.uncoupled_base_user_values(scenario.user_values)
      end

      def couplings_manager
        @couplings_manager ||= CouplingsManager.new(scenario, params, current_user)
      end

      def coerce_provided_value(key, value)
        input = Input.get(key)

        if input.nil?
          nil
        elsif value == 'reset'
          value_from_parent(key) || :reset
        else
          input.coerce(value)
        end
      end

      def value_from_parent(key)
        parent = scenario.parent
        return nil unless parent

        parent.user_values[key] ||
          (parent.respond_to?(:balanced_values) && parent.balanced_values[key])
      end
    end
  end
end
