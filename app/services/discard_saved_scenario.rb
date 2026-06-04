# frozen_string_literal: true

# Discards a saved scenario in MyETM (soft-delete).
class DiscardSavedScenario
  include Dry::Monads[:result]

  def call(id:, client:)
    Success(client.put("/api/v1/saved_scenarios/#{id}/discard").body)
  rescue Faraday::UnprocessableEntityError => e
    Failure(e.response[:body]['errors'])
  rescue Faraday::ResourceNotFound
    Failure(ServiceResponse.not_found)
  end
end
