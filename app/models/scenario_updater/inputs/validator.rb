# frozen_string_literal: true

class ScenarioUpdater
  module Inputs
    # Validates that provided input values exist, are the correct type, and fall within allowed ranges.
    class Validator < Base
      validate :validate_user_values

      def initialize(scenario, provided_values, current_user)
        super(scenario, {}, current_user)
        @provided_values = provided_values
      end

      private

      def validate_user_values
        @provided_values.each do |key, value|
          input = Input.get(key)
          input_data = Input.cache(scenario).read(scenario, input)

          if input_data.blank?
            errors.add(:base, "Input #{key} does not exist")
          elsif input.enum?
            validate_enum_input(key, input_data, value)
          elsif input.unit == 'bool'
            validate_bool_input(key, value)
          else
            validate_and_coerce_numeric_input(key, input_data, value)
          end
        end
      end

      def validate_enum_input(key, input, value)
        return if input[:min].include?(value)

        errors.add(
          :base,
          format(
            'Input %<key>s was %<value>s, but must be one of: %<allowed>s',
            key: key,
            value: value.inspect,
            allowed: input[:min].map(&:inspect).join(', ')
          )
        )
      end

      def validate_and_coerce_numeric_input(key, input, value)
        if value.blank?
          errors.add(:base, "Input #{key} must be numeric")
          return
        end

        min = input[:min]
        max = input[:max]

        # Coerce to step value if present
        if input[:step].present? && input[:step] > 0
          value = coerce_to_step(value, min, input[:step])
          @provided_values[key] = value
        end

        # Validate min/max after coercion
        if value < min
          errors.add(:base, "Input #{key} cannot be less than #{min}")
        elsif value > max
          errors.add(:base, "Input #{key} cannot be greater than #{max}")
        end
      end

      # Coerces a value to the nearest valid step
      def coerce_to_step(value, min, step)
        return value if step.nil? || step.zero?

        steps_from_min = ((value - min) / step).round
        min + (steps_from_min * step)
      end

      def validate_bool_input(key, value)
        return if value.present? && value.in?([0, 1])

        errors.add(:base, "Input '#{key}' had value '#{value}', but must be one 0 or 1")
      end
    end
  end
end
