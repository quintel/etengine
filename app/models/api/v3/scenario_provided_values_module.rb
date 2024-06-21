# frozen_string_literal: true

module Api
  module V3
    module ScenarioProvidedValuesModule

      def provided_values
        @provided_values ||= calculate_provided_values
      end

      def provided_values_without_resets
        provided_values.reject { |_, value| value == :reset }
      end

      private

      def calculate_provided_values
        values = @scenario_data[:user_values] || {}

        values.each_with_object({}) do |(key, value), collection|
          collection[key.to_s] = coerce_provided_value(key, value)
        end
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
        parent = @scenario.parent

        return nil unless parent

        parent.user_values[key] ||
          (parent.respond_to?(:balanced_values) && parent.balanced_values[key])
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
