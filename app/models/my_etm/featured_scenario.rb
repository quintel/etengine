# frozen_string_literal: true

module MyEtm
  class FeaturedScenario < ActiveResource::Base
    self.site = "#{Settings.identity.issuer}/api/v1"

    def self.cached_scenarios
      Rails.cache.fetch('featured_scenarios', expires_in: 1.day) do
        connection.get('/api/v1/featured_scenarios/scenarios')
          .body
          .then { |json| JSON.parse(json)['scenarios'] }
      end
    end
  end
end
