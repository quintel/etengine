class ScenarioSerializer < PresetSerializer
  # Creates a new Scenario API serializer.
  #
  # @param [#api_v3_scenario_url] controller
  #   The controller which created the serializer; required to
  # @param [Scenario] scenario
  #   The scenarios for which we want JSON.
  # @param [Hash] options
  #   Options for customising the returned JSON.
  #
  # @see PresetSerializer#initialize
  #
  def initialize(controller, scenario, options = {})
    super(controller, scenario)

    @detailed = options[:detailed].present?
    @inputs   = options[:include_inputs].present?
  end

  # Creates a Hash suitable for conversion to JSON by Rails.
  #
  # @return [Hash{Symbol=>Object}]
  #   The Hash containing the scenario attributes.
  #
  # @see PresetSerializer#as_json
  #
  def as_json(*)
    json = super
    json[:source]     = @resource.source
    json[:template]   = @resource.preset_scenario_id
    # TODO: Remove fallback values for created_at/updated_at when presets are entirely removed.
    json[:created_at] = @resource.created_at || Time.now.utc
    json[:updated_at] = @resource.updated_at || Time.now.utc
    json[:protected]  = @resource.protected?
    json[:esdl_exportable] = @resource.started_from_esdl?

    if @detailed
      json[:user_values] = @resource.user_values
    else
      json.delete(:description)
    end

    if @inputs
      json[:inputs] = InputSerializer.collection(Input.all, @resource, true)
    end

    json
  end
end
