# frozen_string_literal: true

module Qernel
  module Hydrogen
    class ExportAdapter < ConsumerAdapter
      def demand_phase
        :final
      end

      private

      def calculate_carrier_demand
        # Amount of export may be affected by dynamic hydrogen producers
        # (power-to-gas). As the graph has not be re-calculated at this point,
        # we have to figure out the new value manually.
        balance = Helper.supply_demand_balance(@context.plugin)
        balance.positive? ? balance : 0.0
      end
    end
  end
end
