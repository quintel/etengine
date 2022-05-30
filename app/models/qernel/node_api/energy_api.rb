# frozen_string_literal: true

module Qernel
  module NodeApi
    # Contains methods and attributes specific to querying energy nodes.
    class EnergyApi < Base
      include RecursiveMethods

      include RecursiveFactor::PrimaryDemand
      include RecursiveFactor::BioDemand
      include RecursiveFactor::BioEmissions
      include RecursiveFactor::DependentSupply
      include RecursiveFactor::FinalDemand
      include RecursiveFactor::PrimaryCo2
      include RecursiveFactor::Sustainable

      dataset_accessors :from_molecules

      private

      # Energy nodes define demand in MJ, while capacities are specified as MW. 1MW per hour equals
      # 3600 MJ.
      #
      # Returns a numeric.
      def capacity_to_demand_multiplier
        3600.0
      end
    end
  end
end
