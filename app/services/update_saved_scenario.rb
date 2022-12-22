# frozen_string_literal: true

# Creates a new saved scenario on ETModel.
class UpdateSavedScenario
  class Contract < Dry::Validation::Contract
    option :scenario

    json do
      optional(:title).filled(:string)
      optional(:description).filled(:string)
      optional(:scenario_id).filled(:integer)
      optional(:discarded).filled(:bool)
      optional(:private).filled(:bool)
    end

    rule(:scenario_id) do
      key.failure('does not exist') if key? && !scenario
    end
  end

  # Updates the saved scenario.
  #
  # Returns the saved scenario data from ETModel and the Scenario.
  def call(id:, params:, ability:, client:)
    upsert = UpsertSavedScenario.new(
      contract: Contract,
      endpoint_path: "/api/v1/saved_scenarios/#{id}",
      method: :put
    )

    upsert.call(params:, ability:, client:)
  end
end
