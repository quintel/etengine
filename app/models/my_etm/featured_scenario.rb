# frozen_string_literal: true

module MyEtm
  class FeaturedScenario < ActiveResource::Base
    self.site = "#{Settings.identity.issuer}/api/v1"

    def self.cached_ids
      Rails.cache.fetch("featured_scenario_ids", expires_in: 1.week) do
        connection.get("/api/v1/featured_scenarios/scenario_ids")
                  .body
                  .then { |json| JSON.parse(json)["scenario_ids"] }
      end
    end
  end
end
