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

        # Batch fetch all input objects
        input_keys = provided_values_without_resets.keys
        inputs_by_key = input_keys.each_with_object({}) do |key, hash|
          hash[key] = Input.get(key)
        end

        # Batch read all cache data at once
        cache_data = Input.cache(scenario).read_many(scenario, inputs_by_key.values.compact)

        # Validate each input using pre-fetched data
        provided_values_without_resets.each do |key, value|
          input = inputs_by_key[key]
          input_data = input ? cache_data[input.key] : nil

          if input_data.blank?
            errors << "Input #{key} does not exist"
          elsif input.enum?
            validate_enum_input(key, input_data, value, errors)
          elsif input.unit == 'bool'
            validate_bool_input(key, value, errors)
          else
            # Skip range validation for share group inputs - they'll be validated after balancing
            validate_numeric_input(key, input, input_data, value, errors)
          end
        end

        errors.empty? ? Success(provided_values) : Failure(errors)
      end

      private

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

        min = input_data[:min]
        max = input_data[:max]
        step = input_data[:step]

        # Validate step alignment if step is defined
        if step.present? && step > 0
          unless on_valid_step?(value, min, step)
            nearest_lower = nearest_lower_step(value, min, step)
            nearest_higher = nearest_lower + step

            # Round to remove floating point artifacts
            precision = decimal_places(step)
            nearest_lower = nearest_lower.round(precision)
            nearest_higher = nearest_higher.round(precision)

            errors << "Input #{key} value #{value} must align with step size #{step}. " \
                      "Nearest valid values: #{nearest_lower} or #{nearest_higher}"
            return
          end
        end

        # Validate min/max on actual value (not coerced)
        if value < min
          errors << "Input #{key} cannot be less than #{min}"
        elsif value > max
          errors << "Input #{key} cannot be greater than #{max}"
        end
      end

      # Checks if a value aligns with the step from minimum
      def on_valid_step?(value, min, step)
        return true if step.nil? || step.zero?

        # Check if value is within floating point tolerance of a valid step
        remainder = ((value - min) % step).abs
        remainder < 0.0001 || (step - remainder).abs < 0.0001
      end

      # Calculates the nearest valid step value (used for error messages)
      def nearest_lower_step(value, min, step)
        return value if step.nil? || step.zero?

        steps_from_min = ((value - min) / step).round
        min + (steps_from_min * step)
      end

      # Determines number of decimal places for a number
      def decimal_places(num)
        return 0 if num.nil? || num.to_i == num

        # Convert to string and count decimal places
        num_str = num.to_s
        return 0 unless num_str.include?('.')

        decimal_part = num_str.split('.')[1]
        # Remove trailing zeros
        decimal_part.gsub(/0+$/, '').length
      end

      def validate_bool_input(key, value, errors)
        return if value.present? && value.in?([0, 1])

        errors << "Input '#{key}' had value '#{value}', but must be one 0 or 1"
      end
    end
  end
end
