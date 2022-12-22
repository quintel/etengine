# frozen_string_literal: true

# Creates a new saved scenario on ETModel.
class CreateSavedScenario
  class Contract < Dry::Validation::Contract
    option :scenario

    json do
      required(:title).filled(:string)
      optional(:description).filled(:string)
      required(:scenario_id).filled(:integer)
      optional(:private).filled(:bool)
    end

    rule(:scenario_id) do
      key.failure('does not exist') if key? && !scenario
    end
  end

  # Creates the saved scenario.
  #
  # Returns the saved scenario data from ETModel and the Scenario.
  def call(params:, ability:, client:)
    upsert = UpsertSavedScenario.new(
      contract: Contract,
      endpoint_path: '/api/v1/saved_scenarios',
      method: :post
    )

    upsert.call(params:, ability:, client:)
  end
end
