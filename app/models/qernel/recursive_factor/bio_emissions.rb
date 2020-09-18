# frozen_string_literal: true

module Qernel
  module RecursiveFactor
    # Calculates potential CO2 emissions resulting from the use of bio resources.
    module BioEmissions
      # Public: Calculates the amount of CO2 captured on the node.
      #
      # Returns a numeric in kg.
      def captured_bio_emissions
        if ccs_capture_rate&.positive?
          primary_co2_emission_of_bio_carriers * ccs_capture_rate
        else
          0.0
        end
      end

      # Public: Calculates all captured CO2 emissions which result from energy used by this node.
      #
      # Note that this does not mean that the node captures the CO2 itself; for that, use
      # `captured_bio_emissions`). Rather, CO2 is captured on the node OR somewhere to the right
      # (supply-side) of the node.
      #
      # For example:
      #   [A] <- [B] <- [C] <- [D]
      #
      # If `[C]` has a `ccs_capture_rate` value, carbon capture occurs on node `[C]`. Calling
      # `inherited_captured_bio_emissions` on `[A]` will continually recurse to the right until it
      # finds the `ccs_capture_rate` on `[C]`, and then propages the value (accounting for shares
      # and conversions) to the left.
      #
      # Returns a numeric in kg.
      def inherited_captured_bio_emissions
        fetch(:captured_bio_emissions) do
          case ccs_capture_rate
          when nil
            inputs.sum do |input|
              input.edges.sum { |edge| captured_bio_emissions_from_supplier(edge) }
            end
          when 0.0
            0.0
          else
            captured_bio_emissions
          end
        end
      end

      private

      # Internal: Determines the total amount of CO2 capturable by this node.
      #
      # Note that the _actual_ amount of CO2 captured may be lower.
      # See BioEmissions#captured_bio_emissions.
      #
      # Returns a numeric in kg.
      def primary_co2_emission_of_bio_carriers
        fetch(:primary_co2_emission_of_bio_carriers) do
          if ccs_capture_rate&.positive?
            (demand || 0.0) * recursive_factor(:bio_co2_per_mj_factor)
          else
            0.0
          end
        end
      end

      # Internal: Determines the factor of CO2 which may be captured resulting from energy demand on
      # this node.
      #
      # See BioEmissions#primary_co2_emission_of_bio_carriers.
      #
      # Returns a numeric.
      def bio_co2_per_mj_factor(edge)
        return nil if edge.nil?

        # Stop traversing immediately upon encounting an edge with a `potential_co2_per_mj`
        # attribute. Edges with no value will return nil, continuing traversal to the right.
        edge.query.potential_co2_per_mj
      end

      # Internal: Given an input edge from this node, calculates the bio emissions which are
      # captured resulting from the energy which passes through the edge.
      #
      # See BioEmissions#inherited_captured_bio_emissions for details.
      #
      # Returns a numeric in kg.
      def captured_bio_emissions_from_supplier(edge)
        if edge.demand.positive?
          edge.rgt_node.query.inherited_captured_bio_emissions *
            edge.parent_share * edge.rgt_output.conversion
        else
          # Don't recurse through any edge with no demand. There won't be any emissions from
          # this path, and we'll get caught in loops in the graph.
          0.0
        end
      end
    end
  end
end
