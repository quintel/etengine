# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Validates that input share groups sum to 100% within an acceptable tolerance (0.01).
    class ValidateBalance
      include Dry::Monads[:result]

      TOLERANCE = 0.01

      def call(scenario, user_values, balanced_values, provided_values, skip_validation = false)
        return Success(true) if skip_validation

        errors = []

        each_group(provided_values) do |group, inputs|
          values = inputs.map do |input|
            input_cache = Input.cache(scenario).read(scenario, input)
            next if input_cache[:disabled]

            user_values[input.key] ||
              balanced_values[input.key] ||
              input_cache[:default]
          end.compact

          next if values.sum.between?(100 - TOLERANCE, 100 + TOLERANCE)

          info = inputs.map(&:key).zip(values).map do |key, value|
            "#{key}=#{value}"
          end.join(' ')

          errors << "#{group.to_s.inspect} group does not balance: group sums to " \
                    "#{values.sum} using #{info}"
        end

        errors.empty? ? Success(true) : Failure(errors)
      end

      private

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
