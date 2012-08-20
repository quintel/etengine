module Api
  module V3
    class ScenarioPresenter < PresetPresenter
      # Creates a new Scenario API presenter.
      #
      # @param [#api_v3_scenario_url] controller
      #   The controller which created the presenter; required to
      # @param [Scenario] scenario
      #   The scenarios for which we want JSON.
      # @param [true, false] detailed
      #   Show extra details with the scenario such as the description and
      #   FCE status?
      #
      # @see PresetPresenter#initialize
      #
      def initialize(controller, scenario, detailed = false)
        super(controller, scenario)
        @detailed = detailed
      end

      # Creates a Hash suitable for conversion to JSON by Rails.
      #
      # @return [Hash{Symbol=>Object}]
      #   The Hash containing the scenario attributes.
      #
      # @see PresetPresenter#as_json
      #
      def as_json(*)
        json = super

        json[:source]     = @resource.source
        json[:template]   = @resource.preset_scenario_id
        json[:created_at] = @resource.created_at

        if @detailed
          json[:use_fce] = @resource.use_fce
        else
          json.delete(:description)
        end

        json
      end
    end # ScenarioPresenter
  end # V3
end # Api
