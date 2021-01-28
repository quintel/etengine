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
    json[:created_at] = @resource.created_at
    json[:updated_at] = @resource.updated_at
    json[:protected]  = @resource.protected?

    if @detailed
      json[:use_fce]     = @resource.use_fce
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
