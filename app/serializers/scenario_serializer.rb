class ScenarioSerializer
  # Creates a new Scenario API serializer.
  #
  # @param [#api_v3_scenario_url] controller
  #   The controller which created the serializer; required to
  # @param [Scenario] scenario
  #   The scenarios for which we want JSON.
  # @param [Hash] options
  #   Options for customising the returned JSON.
  #
  def initialize(controller, scenario, options = {})
    @controller = controller
    @resource   = scenario

    @inputs = ActiveModel::Type::Boolean.new.cast(options[:include_inputs])
  end

  # Creates a Hash suitable for conversion to JSON by Rails.
  #
  # @return [Hash{Symbol=>Object}]
  #   The Hash containing the scenario attributes.
  #
  def as_json(*)
    json = @resource.as_json(
      only: %i[
        id area_code end_year scaling source private keep_compatible
        created_at updated_at user_values balanced_values metadata
      ],
      methods: %i[start_year],
      include: { owner: { only: %i[id name] } }
    ).symbolize_keys

    json[:template]        = @resource.preset_scenario_id
    json[:esdl_exportable] = @resource.started_from_esdl?
    json[:url]             = @controller.api_v3_scenario_url(@resource)

    if @inputs
      json[:inputs] = InputSerializer.collection(Input.all, @resource, extra_attributes: true)
    end

    json
  end
end
