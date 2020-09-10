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

      private

      # Energy nodes use full_load_seconds in order to implicitly convert from MJ to MW, due to
      # demands being specified in MJ and capacities in MW. Molecule node units and capacities use
      # the same unit: kg.
      #
      # Returns a numeric.
      def capacity_to_demand_multiplier
        3600.0
      end
    end
  end
end
