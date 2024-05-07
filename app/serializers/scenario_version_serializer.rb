class ScenarioVersionSerializer
  # Creates a new Scenario Version Tag API serializer.
  #
  # @param [Scenario] scenario
  #   The scenarios for which we want JSON.
  #
  def initialize(scenario)
    @resource = scenario.scenario_version_tag
    @last_updated_at = scenario.updated_at
  end

  # Creates a Hash suitable for conversion to JSON by Rails.
  #
  # @return [Hash{Symbol=>Object}]
  #   The Hash containing the scenario version tag attributes.
  #
  def as_json(*)
    hash = @resource ? @resource.as_json : {}
    hash[:last_updated_at] = @last_updated_at

    hash
  end
end
