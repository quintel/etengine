class ScenarioVersionSerializer
  # Creates a new Scenario Version Tag API serializer.
  #
  # @param [Scenario] scenario
  #   The scenarios for which we want JSON.
  #
  def initialize(scenario)
    @resource = scenario.scenario_version_tag
  end

  # Creates a Hash suitable for conversion to JSON by Rails.
  #
  # @return [Hash{Symbol=>Object}]
  #   The Hash containing the scenario version tag attributes.
  #
  def as_json(*)
    @resource ? @resource.as_json : {}
  end
end
