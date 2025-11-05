# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Validates that input share groups sum to 100% within an acceptable tolerance (0.01).
    class ValidateBalance
      include Dry::Monads[:result]

      TOLERANCE = 1.0E-12
      SHARE_GROUP_TOTAL = 1.0E2

      def call(scenario, user_values:, balanced_values:, provided_values:, skip_validation: false)
        return Success(true) if skip_validation

        errors = []

        ShareGroups.each(provided_values) do |group, inputs|
          check_group_balance(group, inputs, scenario, user_values, balanced_values, errors)
        end

        errors.empty? ? Success(true) : Failure(errors)
      end

      private

      def check_group_balance(group, inputs, scenario, user_values, balanced_values, errors)
        values = inputs.map do |input|
          input_cache = Input.cache(scenario).read(scenario, input)
          next if input_cache[:disabled]

          user_values[input.key] || balanced_values[input.key] || input_cache[:default]
        end.compact

        return if values.sum.between?(SHARE_GROUP_TOTAL - TOLERANCE, SHARE_GROUP_TOTAL + TOLERANCE)

        info = inputs.map(&:key).zip(values).map { |key, value| "#{key}=#{value}" }.join(' ')
        errors << "#{group.to_s.inspect} group does not balance: group sums to " \
                  "#{values.sum} using #{info}"
      end
    end
  end
end
