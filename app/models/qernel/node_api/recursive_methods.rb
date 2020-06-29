# frozen_string_literal: true

module Qernel
  class NodeApi
    # Aliases of RecursiveFactor methods.
    module RecursiveMethods
      include CalculationUnits

      # Returns a numeric value in MJ.
      def max_demand_recursive
        node.max_demand_recursive!
      end

      # Public: The total primary demand of fossil primary carriers of the node.
      #
      # Returns a numeric value in MJ.
      delegate :primary_demand_of_fossil, to: :node

      # Public: The total primary demand of sustainable primary carriers of the node.
      #
      # Returns a numeric value in MJ.
      delegate :primary_demand_of_sustainable, to: :node

      delegate :sustainability_share, to: :node

      # Public: Inverse of sustainability_share. The share of energy which is not sustainable.
      #
      # Returns a numeric.
      def non_renewable_share
        1.0 - (sustainability_share || 0.0)
      end

      # Public: Returns the cost of MJ energy.
      delegate :weighted_carrier_cost_per_mj, to: :node

      # Public: Returns the CO2 emissions (in kg) per MJ energy.
      delegate :weighted_carrier_co2_per_mj, to: :node
    end
  end
end
