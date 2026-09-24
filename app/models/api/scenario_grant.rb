# frozen_string_literal: true

module Api
  # Reads the scenario_access claim from a verified identity token: a signed statement, minted only
  # by MyETM, that its bearer may read or write one specific scenario at a given level.
  class ScenarioGrant
    CLAIM = 'scenario_access'
    WRITE = 'write'

    attr_reader :scenario_id, :level

    def initialize(scenario_id:, level:)
      @scenario_id = scenario_id.to_i
      @level = level.to_s
    end

    # Builds a grant from a decoded token, or nil when the claim is absent or malformed.
    def self.from_token(token)
      claim = token && token[CLAIM]
      return nil if claim.blank?

      scenario_id = claim['scenario_id'] || claim[:scenario_id]
      return nil if scenario_id.blank?

      new(scenario_id: scenario_id, level: claim['level'] || claim[:level])
    end

    def write?
      level == WRITE
    end
  end
end
