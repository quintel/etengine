# frozen_string_literal: true

module Qernel
  module EdgeApi
    # An implementation of EdgeApi for edges which are part of the energy graph.
    class Energy < Base
      dataset_writer :co2_per_mj

      delegated_calculation :primary_demand, true
      delegated_calculation :primary_demand_of, true
      delegated_calculation :primary_demand_of_carrier, true
      delegated_calculation :sustainability_share
      delegated_calculation :dependent_supply_of_carrier, true

      # Public: Returns how much CO2 is emitted per MJ passing through the edge.
      #
      # Delegates to the carrier if no custom edge value is set. Note that setting a custom
      # `co2_per_mj` only has an effect if the edge would be used to calculate CO2 emissions.
      #
      # See Qernel::RecursiveFactor::PrimaryCo#co2_per_mj_factor
      #
      # Returns a numeric.
      def co2_per_mj
        fetch(:co2_per_mj) { carrier.co2_per_mj }
      end
    end
  end
end
