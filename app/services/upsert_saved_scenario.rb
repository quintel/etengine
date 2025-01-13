# frozen_string_literal: true

# Creates or updates a saved scenario on ETModel.
#
# Must be provided with the contract class used to validate the params, the path to the API
# endpoint for creating or updating the saved scenario, and the HTTP method to be used.
#
# For example:
#
#   UpsertSavedScenario.new(CreateSavedScenario::Contract, '/api/v1/saved_scenarios', :post)
#   UpsertSavedScenario.new(UpdateSavedScenario::Contract, '/api/v1/saved_scenarios/1', :put)
class UpsertSavedScenario
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call)

  def initialize(contract:, endpoint_path:, method:)
    @contract = contract
    @endpoint_path = endpoint_path
    @method = method
  end

  # Creates the saved scenario.
  #
  # Returns the saved scenario data from ETModel and the Scenario.
  def call(params:, ability:, client:)
    scenario       = find_scenario(ability, params[:scenario_id])
    params         = yield validate(scenario, params)
    saved_scenario = yield upsert_saved_scenario(client, full_params(params, scenario))

    Success([saved_scenario, scenario])
  end

  private

  def validate(scenario, params)
    result = @contract.new(scenario:).call(params)
    result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
  end

  def find_scenario(ability, id)
    Scenario.accessible_by(ability).find_by(id:) if id
  end

  def upsert_saved_scenario(client, params)
    Success(client.public_send(@method, @endpoint_path, params).body)
  rescue Faraday::UnprocessableEntityError => e
    Failure(e.response[:body]['errors'])
  rescue Faraday::ResourceNotFound
    Failure(ServiceResponse.not_found)
  end

  # Decorates the params with the scenario's area code and end year when a scenario_id is set.
  def full_params(params, scenario)
    scenario ? params.merge(area_code: scenario.area_code, end_year: scenario.end_year, version: scenario.version) : params
  end
end
