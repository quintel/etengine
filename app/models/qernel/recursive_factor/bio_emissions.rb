# frozen_string_literal: true

module Qernel
  module RecursiveFactor
    # Calculates potential CO2 emissions resulting from the use of bio resources.
    module BioEmissions
      def primary_co2_emission_of_bio_carriers
        fetch(:primary_co2_emission_of_bio_carriers) do
          (demand_of_bio_resources_including_abroad || 0.0) *
            recursive_factor(:bio_co2_per_mj_factor)
        end
      end

      def bio_co2_per_mj_factor(edge)
        return nil if edge.nil?

        # Stop traversing immediately upon encounting an edge with a `potential_co2_per_mj`
        # attribute. Edges with no value will return nil, continuing traversal to the right.
        edge.query.potential_co2_per_mj
      end
    end
  end
end
