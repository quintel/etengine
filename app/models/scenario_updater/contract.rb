# frozen_string_literal: true

class ScenarioUpdater
  # Contract for validating scenario update params.
  class Contract < Dry::Validation::Contract
    option :scenario
    option :current_user

    params do
      optional(:scenario).hash
      optional(:reset).filled(:bool)
      optional(:uncouple).filled(:bool)
      optional(:autobalance)
      optional(:force_balance).filled(:bool)
      optional(:gqueries).array(:string)
    end
  end
end
