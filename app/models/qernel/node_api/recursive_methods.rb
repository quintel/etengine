# frozen_string_literal: true

module Qernel
  class NodeApi
    # Aliases of RecursiveFactor methods.
    module RecursiveMethods
      include CalculationUnits

      def max_demand_recursive
        node.max_demand_recursive!
      end
      unit_for_calculation 'max_demand_recursive', 'MJ'

      delegate :primary_demand_of_fossil, to: :node
      unit_for_calculation 'primary_demand_of_fossil', 'MJ'

      delegate :primary_demand_of_sustainable, to: :node
      unit_for_calculation 'primary_demand_of_sustainable', 'MJ'

      delegate :sustainability_share, to: :node

      # Inverse of sustainability_share https://github.com/dennisschoenmakers/etengine/issues/272
      def non_renewable_share
        1.0 - (sustainability_share || 0.0)
      end
      unit_for_calculation 'non_renewable_share', 'factor'

      delegate :weighted_carrier_cost_per_mj, to: :node
      unit_for_calculation 'weighted_carrier_cost_per_mj', 'euro'

      delegate :weighted_carrier_co2_per_mj, to: :node
      unit_for_calculation 'weighted_carrier_co2_per_mj', 'kg'
    end
  end
end
