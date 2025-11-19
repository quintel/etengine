# frozen_string_literal: true

# Creates or updates a collection on MyETM.
#
# Must be provided with the path to the API endpoint for creating or updating the saved scenario,
# and the HTTP method to be used.
#
# For example:
#
#   UpsertTransitionPath.new('/api/v1/saved_scenarios', :post)
#   UpsertTransitionPath.new('/api/v1/saved_scenarios/1', :put)
class UpsertTransitionPath
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call)

  def initialize(endpoint_path:, method:)
    @endpoint_path = endpoint_path
    @method = method
  end

  # Creates or updates the collection.
  #
  # Returns the collection data from MyETM.
  def call(params:, client:)
    result = yield upsert_transition_path(client, params)

    Success(result)
  end

  private

  def upsert_transition_path(client, params)
    Success(client.public_send(@method, @endpoint_path, params).body)
  rescue Faraday::UnprocessableEntityError => e
    Failure(e.response[:body]['errors'])
  rescue Faraday::ResourceNotFound
    Failure(ServiceResponse.not_found)
  end
end
