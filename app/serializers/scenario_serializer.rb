class ScenarioSerializer
  # Creates a new Scenario API serializer.
  #
  # @param [#api_v3_scenario_url] controller
  #   The controller which created the serializer; required to
  # @param [Scenario] scenario
  #   The scenarios for which we want JSON.
  #
  def initialize(controller, scenario)
    @controller = controller
    @resource   = scenario
  end

  # Creates a Hash suitable for conversion to JSON by Rails.
  #
  # @return [Hash{Symbol=>Object}]
  #   The Hash containing the scenario attributes.
  #
  def as_json(*)
    json = @resource.as_json(
      only: %i[
        id area_code end_year source private keep_compatible
        created_at updated_at user_values balanced_values metadata
      ],
      methods: %i[start_year coupling]
    ).symbolize_keys

    json[:users]    = @resource.scenario_users.map { |su| { id: su.user&.id, email: su.email, role: User::ROLES[su.role_id] } }
    json[:scaling]  = @resource.scaler&.as_json(except: %i[id scenario_id])
    json[:template] = @resource.preset_scenario_id
    json[:url]      = @controller.api_v3_scenario_url(@resource)

    json
  end
end
