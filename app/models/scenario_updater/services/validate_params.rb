# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Validates request parameters
    # Returns Success with sanitized params or Failure with error hash.
    class ValidateParams
      include Dry::Monads[:result]

      def call(scenario, params, current_user)
        contract = Contract.new(scenario: scenario, current_user: current_user)
        result = contract.call(params)

        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end
    end
  end
end
