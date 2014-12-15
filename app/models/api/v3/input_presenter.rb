module Api
  module V3
    class InputPresenter
      # Given an array of inputs, returns JSON for all of them.
      #
      # @param [Array<Input>] inputs
      #   The input for which we want JSON.
      # @param [Scenario] scenario
      #   The scenario whose values are being rendered.
      # @param [true, false] extras
      #   Do you want the extra attributes (key, unit, step) to be included in
      #   the output?
      def self.collection(inputs, scenario, extras = false)
        inputs.each_with_object(Hash.new) do |input, data|
          data[input.key] = InputPresenter.new(input, scenario, extras)
        end
      end

      # Creates a new Input API presenter.
      #
      # @param [Input] input
      #   The input for which we want JSON.
      # @param [Scenario] scenario
      #   The scenario whose values are being rendered.
      # @param [true, false] extra_attributes
      #   Do you want the extra attributes (key, unit, step) to be included in
      #   the output?
      #
      def initialize(input, scenario, extra_attributes = false)
        @input            = input
        @scenario         = scenario
        @extra_attributes = extra_attributes
      end

      # Creates a Hash suitable for conversion to JSON by Rails.
      #
      # @return [Hash{Symbol=>Object}]
      #   The Hash containing the input attributes.
      #
      def as_json(*)
        json     = Hash.new

        values   = Input.cache(@scenario).read(@scenario, @input)

        user_values      = HashWithIndifferentAccess.new(@scenario.user_values)
        balanced_values  = HashWithIndifferentAccess.new(@scenario.balanced_values)

        user_val = user_values[@input.key] || balanced_values[@input.key]

        json[:min]         = values[:min]
        json[:max]         = values[:max]
        json[:default]     = values[:default]

        json[:user]        = user_val           if user_val.present?
        json[:disabled]    = true               if values[:disabled]
        json[:cache_error] = values[:error]     if values[:error]

        json[:share_group] = @input.share_group if @input.share_group.present?

        if @extra_attributes
          json[:step] = values[:step] || @input.step_value
          json[:code] = @input.key
          json[:unit] = @input.unit
        end

        if values[:label].present?
          json[:label] = { value: values[:label], suffix: @input.label }
        end

        json
      end
    end # Input
  end # V3
end # Api
