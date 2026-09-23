# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Validates that input values exist and have correct types.
    # Range validation is skipped for share group inputs as they will be balanced later.
    class ValidateInputValues
      include Dry::Monads[:result]

      def call(scenario, provided_values, skip_validation = false)
        return Success(provided_values) if skip_validation

        errors = []
        provided_values_without_resets = provided_values.reject { |_, value| value == :reset }
        inputs_by_key, cache_data = fetch_input_data(scenario, provided_values_without_resets)

        provided_values_without_resets.each do |key, value|
          validate_single_input(key, value, inputs_by_key, cache_data, errors)
        end

        errors.empty? ? Success(provided_values) : Failure(errors)
      end

      private

      def fetch_input_data(scenario, provided_values_without_resets)
        input_keys = provided_values_without_resets.keys
        inputs_by_key = input_keys.each_with_object({}) do |key, hash|
          hash[key] = Input.get(key)
        end
        cache_data = Input.cache(scenario).read_many(scenario, inputs_by_key.values.compact)

        [inputs_by_key, cache_data]
      end

      def validate_single_input(key, value, inputs_by_key, cache_data, errors)
        input = inputs_by_key[key]
        input_data = input ? cache_data[input.key] : nil

        if input_data.blank?
          errors << "Input #{key} does not exist"
        elsif input.enum?
          validate_enum_input(key, input_data, value, errors)
        elsif input.unit == 'bool'
          validate_bool_input(key, value, errors)
        else
          validate_numeric_input(key, input, input_data, value, errors)
        end
      end

      def validate_enum_input(key, input, value, errors)
        return if input[:min].include?(value)

        errors << format(
          'Input %<key>s was %<value>s, but must be one of: %<allowed>s',
          key: key,
          value: value.inspect,
          allowed: input[:min].map(&:inspect).join(', ')
        )
      end

      def validate_numeric_input(key, input, input_data, value, errors)
        if value.blank?
          errors << "Input #{key} must be numeric"
          return
        end

        # Skip range validation for share group inputs - they can temporarily exceed ranges
        # and will be validated after balancing
        return if input.share_group.present?

        # Validate step alignment first - skip min/max check if step invalid
        step_valid = validate_step(key, value, input_data[:min], input_data[:step], errors)
        return unless step_valid

        validate_min_max(key, value, input_data[:min], input_data[:max], errors)
      end

      def validate_step(key, value, min, step, errors)
        return true unless step.present? && step.positive?
        return true if value_on_valid_step?(value, min, step)

        nearest_lower = calculate_nearest_step(value, min, step)
        nearest_higher = nearest_lower + step
        precision = decimal_places(step)

        errors << "Input #{key} value #{value} must align with step size #{step}. " \
                  "Nearest valid values: #{nearest_lower.round(precision)} or #{nearest_higher.round(precision)}"

        false
      end

      def value_on_valid_step?(value, min, step)
        remainder = ((value - min) % step).abs
        remainder < 0.0001 || (step - remainder).abs < 0.0001
      end

      def calculate_nearest_step(value, min, step)
        steps_from_min = ((value - min) / step).round
        min + (steps_from_min * step)
      end

      def decimal_places(num)
        return 0 if num.to_i == num

        num_str = num.to_s
        return 0 unless num_str.include?('.')

        num_str.split('.')[1].gsub(/0+$/, '').length
      end

      def validate_min_max(key, value, min, max, errors)
        if value < min
          errors << "Input #{key} cannot be less than #{min}"
        elsif value > max
          errors << "Input #{key} cannot be greater than #{max}"
        end
      end

      def validate_bool_input(key, value, errors)
        return if value.present? && value.in?([0, 1])

        errors << "Input '#{key}' had value '#{value}', but must be one 0 or 1"
      end
    end
  end
end
