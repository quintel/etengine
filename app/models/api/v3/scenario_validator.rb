# frozen_string_literal: true

module Api
  module V3
    class ScenarioValidator
      def initialize(scenario:, params:, provided_values:, user_values:, balanced_values:, each_group_proc:)
        @scenario = scenario
        @params = params
        @provided_values = provided_values
        @user_values = user_values
        @balanced_values = balanced_values
        @each_group_proc = each_group_proc
      end

      def validate_user_values(errors)
        @provided_values.each do |key, value|
          input = Input.get(key)
          input_data = Input.cache(@scenario).read(@scenario, input)

          if input_data.blank?
            errors.add(:base, "Input #{key} does not exist")
          elsif input.enum?
            validate_enum_input(key, input_data, value, errors)
          elsif input.unit == 'bool'
            validate_bool_input(key, value, errors)
          else
            validate_numeric_input(key, input_data, value, errors)
          end
        end
      end

      def validate_groups_balance(errors)
        @each_group_proc.call(@provided_values) do |group, inputs|
          values = inputs.map do |input|
            input_cache = Input.cache(@scenario).read(@scenario, input)

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

      private

      def validate_enum_input(key, input, value, errors)
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

      def validate_numeric_input(key, input, value, errors)
        if value.blank?
          errors.add(:base, "Input #{key} must be numeric")
          return
        end

        if value < (min = input[:min])
          errors.add(:base, "Input #{key} cannot be less than #{min}")
        elsif value > (max = input[:max])
          errors.add(:base, "Input #{key} cannot be greater than #{max}")
        end
      end

      def validate_bool_input(key, value, errors)
        return if value.present? && value.in?([0, 1])

        errors.add(:base, "Input '#{key}' had value '#{value}', but must be one 0 or 1")
      end
    end
  end
end
