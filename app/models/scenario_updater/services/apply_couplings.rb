# frozen_string_literal: true

class ScenarioUpdater
  module Services
    # Applies coupling changes to the scenario (mutation).
    class ApplyCouplings
      include Dry::Monads[:result]

      def call(scenario, coupling_state)
        # Apply active couplings list if provided
        if coupling_state[:active_couplings]
          scenario.active_couplings = []
          coupling_state[:active_couplings].each do |coupling|
            scenario.activate_coupling(coupling)
          end
        end

        # Activate couplings from provided values
        coupling_state[:couplings_to_activate].each do |group|
          scenario.activate_coupling(group)
        end

        Success(scenario)
      end
    end
  end
end
