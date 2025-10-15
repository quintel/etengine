# frozen_string_literal: true

class ScenarioUpdater
  module Inputs
    # Validates that input share groups sum to 100% within an acceptable tolerance (0.01)
    class BalanceValidator < Base
      validate :validate_groups_balance

      def initialize(scenario, user_values, balanced_values, provided_values)
        super(scenario, {}, nil)
        @user_values = user_values
        @balanced_values = balanced_values
        @provided_values = provided_values
      end

      private

      def validate_groups_balance
        each_group(@provided_values) do |group, inputs|
          values = inputs.map do |input|
            input_cache = Input.cache(scenario).read(scenario, input)
            next if input_cache[:disabled]

            @user_values[input.key] ||
              @balanced_values[input.key] ||
              input_cache[:default]
          end.compact

          next if values.sum.between?(99.99, 100.01)

          info = inputs.map(&:key).zip(values).map do |key, value|
            "#{key}=#{value}"
          end.join(' ')

          errors.add(:base,
            "#{group.to_s.inspect} group does not balance: group sums to " \
            "#{values.sum} using #{info}")
        end
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
