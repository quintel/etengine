# frozen_string_literal: true

module Qernel
  module Reconciliation
    class ImportAdapter < ProducerAdapter
      def demand_phase
        :final
      end

      private

      def calculate_carrier_demand
        # Amount of import may be affected by dynamic producers (power-to-gas).
        # As the graph has not be re-calculated at this point, we have to figure
        # out the new value manually.
        balance = Helper.supply_demand_balance(@context.plugin)
        balance.negative? ? balance.abs : 0.0
      end
    end
  end
end
