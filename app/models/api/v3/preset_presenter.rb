module Api
  module V3
    class PresetPresenter
      # Creates a new Preset API presenter.
      #
      # @param [#api_v3_scenario_url] controller
      #   The controller which created the presenter; required to
      # @param [Preset] preset
      #   The scenario preset for which we want JSON.
      #
      def initialize(controller, preset)
        @controller = controller
        @resource   = preset
      end

      # Creates a Hash suitable for conversion to JSON by Rails.
      #
      # @return [Hash{Symbol=>Object}]
      #   The Hash containing the preset scenario attributes.
      #
      def as_json(*)
        json = Hash.new

        json[:id]          = @resource.id
        json[:title]       = @resource.title
        json[:area_code]   = @resource.area_code
        json[:end_year]    = @resource.end_year
        json[:description] = @resource.description
        json[:url]         = @controller.api_v3_scenario_url(@resource)

        json
      end
    end # PresetPresenter
  end # V3
end # Api
