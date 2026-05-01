# frozen_string_literal: true

module Qernel
  module NodeApi
    # Calculates emissions reporting metrics for molecule nodes.
    #
    # MoleculeEmissions tracks emissions directly from molecule node demands and connected GHG flows.
    #
    # For molecule nodes:
    # - CO2 production = node demand (already in kg CO2/year from emissions.csv)
    # - Other GHG = sum of connected other_ghg nodes via EMISSIONS() function
    # - CO2 capture = placeholder (returns 0.0 for now)
    # - Total GHG = CO2 production - capture + other GHG
    module MoleculeEmissions
      # CO2 production at this molecule node.
      #
      # Returns the node demand if the node has CO2 as a carrier (input or output).
      # For molecule nodes representing CO2 flows, the demand directly represents
      # the amount of CO2 in kg/year.
      #
      # @return [Float, nil] CO2 production in kg, or nil if node is not in emissions group
      def direct_reporting_emissions_co2_production
        with_emissions_node do
          node.input(:co2) ? node.demand : 0.0
        end
      end

      # Other greenhouse gas emissions (non-CO2) at this molecule node.
      #
      # Returns the node demand if the node has other_ghg as a carrier (input or output).
      # For molecule nodes representing other GHG flows (CH4, N2O, etc.), the demand
      # represents the amount in kg CO2-equivalent/year.
      #
      # @return [Float, nil] Other GHG emissions in kg CO2-equivalent, or nil if node is not in emissions group
      def direct_reporting_emissions_other_ghg_emissions
        with_emissions_node do
          node.input(:other_ghg) ? node.demand : 0.0
        end
      end

      # CO2 capture at this molecule node.
      #
      # Currently always eturns 0.0.
      #
      # @return [Float, nil] CO2 capture in kg, or nil if node is not in emissions group
      def direct_reporting_emissions_co2_capture
        with_emissions_node do
          0.0
        end
      end

      # Total greenhouse gas emissions from this molecule node.
      #
      # Formula: CO2 production - CO2 capture + other GHG emissions
      #
      # @return [Float, nil] Total GHG emissions in kg CO2-equivalent, or nil if node is not in emissions group
      def direct_reporting_emissions_total_ghg_emissions
        with_emissions_node do
          direct_reporting_emissions_co2_production -
            direct_reporting_emissions_co2_capture +
            direct_reporting_emissions_other_ghg_emissions
        end
      end

      private

      # Yields the given block only if the node belongs to the :emissions group.
      #
      # @return [Float, nil] Result of the block, or nil if node is not in emissions group
      def with_emissions_node
        return nil unless node.groups.include?(:emissions)
        yield
      end
    end
  end
end
