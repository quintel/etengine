# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Validates request parameter types
    # Returns Success with sanitized params or Failure with error hash.
    class ValidateParams
      include Dry::Monads[:result]

      # Validation schema for update parameters
      SCHEMA = Dry::Validation.Contract do
        params do
          optional(:scenario).hash
          optional(:reset).filled(:bool)
          optional(:uncouple).filled(:bool)
          optional(:autobalance)
          optional(:force_balance).filled(:bool)
          optional(:gqueries).array(:string)
        end
      end

      def call(scenario, params, current_user)
        result = SCHEMA.call(params)

        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end
    end
  end
end
