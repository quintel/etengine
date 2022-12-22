# frozen_string_literal: true

# Deletes a saved scenario in ETModel.
class DeleteSavedScenario
  include Dry::Monads[:result]

  def call(id:, client:)
    Success(client.delete("/api/v1/saved_scenarios/#{id}").body)
  rescue Faraday::ResourceNotFound
    Failure(ServiceResponse.not_found)
  end
end
