# frozen_string_literal: true

module Qernel
  module NodeApi
    # Contains methods and attributes specific to querying energy nodes.
    class EnergyApi < Base
      prepend RecursiveMethods

      prepend RecursiveFactor::PrimaryDemand
      prepend RecursiveFactor::BioDemand
      prepend RecursiveFactor::DependentSupply
      prepend RecursiveFactor::FinalDemand
      prepend RecursiveFactor::PrimaryCo2
      prepend RecursiveFactor::WeightedCarrier
      prepend RecursiveFactor::Sustainable
      prepend RecursiveFactor::MaxDemand

      # Final module prepended with any custom EnergyApi feature.
      # TODO: Factor out `prepend` in favour of `include`.
      module EnergyCustomisation
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
end
