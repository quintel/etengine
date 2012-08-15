module Api
  module V3
    class InputPresenter
      # Creates a new Input API presenter.
      #
      # @param [Input] input
      #   The input for which we want JSON.
      # @param [Scenario] scenario
      #   The scenario whose values are being rendered.
      # @param [true, false] include_key
      #   Do you want the input key to be included in the output?
      #
      def initialize(input, scenario, include_key = false)
        @input       = input
        @scenario    = scenario
        @include_key = include_key
      end

      # Creates a Hash suitable for conversion to JSON by Rails.
      #
      # @return [Hash{Symbol=>Object}]
      #   The Hash containing the input attributes.
      #
      def as_json(*)
        json     = Hash.new

        values   = Input.cache.read(@scenario, @input)
        user_val = @scenario.user_values[@input.key || @input.id]

        json[:code]        = @input.key         if @include_key

        json[:min]         = values[:min]
        json[:max]         = values[:max]
        json[:default]     = values[:default]

        json[:user]        = user_val           if user_val.present?
        json[:label]       = values[:label]     if values[:label].present?
        json[:disabled]    = true               if values[:disabled]
        json[:cache_error] = values[:error]     if values[:error]

        json[:share_group] = @input.share_group if @input.share_group.present?

        json
      end
    end # Input
  end # V3
end # Api
