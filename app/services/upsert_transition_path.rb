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
  def call(params:, ability:, client:)
    scenarios = find_scenarios(ability, params[:scenario_ids])
    yield validate_scenario_ids(params[:scenario_ids], scenarios)

    result = yield upsert_transition_path(client, full_params(params))

    Success(result)
  end

  private

  def find_scenarios(ability, ids)
    Scenario.accessible_by(ability).where(id: ids).order(:end_year) if ids
  end

  # Verifies that the user has access to all the scenarios. The params themselves will be validated
  # by MyETM.
  def validate_scenario_ids(ids, scenarios)
    return Success() unless ids

    accessible_ids = scenarios.map(&:id)

    if accessible_ids == ids.sort
      Success(accessible_ids)
    else
      missing_ids = ids - accessible_ids
      Failure(scenario_ids: missing_ids.index_with { |_id| ['does not exist'] })
    end
  end

  def upsert_transition_path(client, params)
    Success(client.public_send(@method, @endpoint_path, params).body)
  rescue Faraday::UnprocessableEntityError => e
    Failure(e.response[:body]['errors'])
  rescue Faraday::ResourceNotFound
    Failure(ServiceResponse.not_found)
  end

  def full_params(params)
    params.merge(version: Settings.version_tag)
  end
end
