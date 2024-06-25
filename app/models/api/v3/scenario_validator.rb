# app/models/api/v3/scenario_validator.rb

module Api
  module V3
    class ScenarioValidator
      include ActiveModel::Validations

      TRUTHY_VALUES = Set.new([true, 'true', '1']).freeze
      FALSEY_VALUES = Set.new([false, 'false', '0']).freeze

      def initialize(scenario, data, provided_values, provided_values_without_resets, user_values, balanced_values, each_group_method, current_user)
        @scenario = scenario
        @data = data
        @provided_values = provided_values
        @provided_values_without_resets = provided_values_without_resets
        @user_values = user_values
        @balanced_values = balanced_values
        @each_group_method = each_group_method
        @current_user = current_user
      end

      def validate
        validate_user_values
        validate_groups_balance
        validate_metadata_size
        errors.empty?
      end

      def self.each_group(scenario, values)
        group_names = values.map do |key, _|
          (input = Input.get(key)) && input.share_group.presence || nil
        end.compact.uniq

        group_names.each do |name|
          yield name, Input.in_share_group(name)
        end

        nil
      end

      private

      def validate_user_values
        @provided_values_without_resets.each do |key, value|
          input = Input.get(key)
          input_data = Input.cache(@scenario).read(@scenario, input)

          if input_data.blank?
            errors.add(:base, "Input #{key} does not exist")
          elsif input.enum?
            validate_enum_input(key, input_data, value)
          elsif input.unit == 'bool'
            validate_bool_input(key, value)
          else
            validate_numeric_input(key, input_data, value)
          end
        end
        validate_privacy_change
      end

      def validate_privacy_change
        if @data.dig(:scenario, :private) && !@current_user
          errors.add(:base, "Guest users cannot change scenario privacy")
        end
      end

      def validate_bool_input(key, value)
        return if value.present? && value.in?([0, 1])
        errors.add(:base, "Input '#{key}' had value '#{value}', but must be one 0 or 1")
      end

      def validate_groups_balance
        @each_group_method.call(@provided_values) do |group, inputs|
          values = inputs.map do |input|
            input_cache = Input.cache(@scenario).read(@scenario, input)
            next if input_cache[:disabled]

            @user_values[input.key] || @balanced_values[input.key] || input_cache[:default]
          end.compact

          next if values.sum.between?(99.99, 100.01)

          info = inputs.map(&:key).zip(values).map do |key, value|
            "#{key}=#{value}"
          end.join(' ')

          errors.add(:base, "#{group.to_s.inspect} group does not balance: group sums to #{values.sum} using #{info}")
        end
      end

      def validate_metadata_size
        errors.add(:base, 'Metadata can not exceed 64Kb') if @data.to_s.bytesize > 64.kilobytes
      end

      def validate_numeric_input(key, input, value)
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
    end
  end
end
