# frozen_string_literal: true

module Qernel
  module NodeApi
    # Calculates direct CO2 emissions from fossil fuels using a mass balance approach.
    #
    # Direct emissions measure the change in carbon stock at a specific node:
    # - Carbon enters via input carriers
    # - Carbon leaves via output carriers
    # - Direct emissions = CO2 released to atmosphere at this location (input - output)
    #
    # For mixed carriers (network gas, crude oil, carrier_mix), composition tracking
    # uses RecursiveFactor::WeightedCarrier to recursively trace CO2 content through the supply chain.
    module DirectEmissions
      # CO2 content of all carriers entering the node (A).
      #
      # @return [Float, nil] Total CO2 content from input carriers in kg, or nil if node is not in emissions group
      def direct_co2_input_content_carriers_fossil
        with_emissions_node do
          inputs.sum do |slot|
            slot.edges.sum do |edge|
              carbon_content = direct_edge_carbon_content(edge)
              (edge.net_demand || 0.0) * carbon_content
            end
          end
        end
      end

      # CO2 content of all carriers leaving the node (C).
      #
      # @return [Float, nil] Total CO2 content from output carriers in kg, or nil if node is not in emissions group
      def direct_co2_output_content_carriers_fossil
        with_emissions_node do
          output_edges.sum do |edge|
            carbon_content = direct_edge_carbon_content(edge)
            (edge.net_demand || 0.0) * carbon_content
          end
        end
      end

      # CO2 emissions produced at this node (E).
      # TODO: extend once capture is included.
      #
      # @return [Float, nil] Direct fossil CO2 emissions in kg, or nil if node is not in emissions group
      def direct_co2_output_production_emissions_fossil
        with_emissions_node do
          direct_co2_input_content_carriers_fossil -
            direct_co2_output_content_carriers_fossil
        end
      end

      # CO2 production - for now equal to E
      #
      # @return [Float, nil] Direct fossil CO2 production in kg, or nil if node is not in emissions group
      def direct_reporting_emissions_co2_production
        with_emissions_node do
          direct_co2_output_production_emissions_fossil
        end
      end

      private

      # Yields the given block only if the node belongs to the :emissions group.
      #
      # @return [Float, nil] Result of the block, or nil if node is not in emissions group
      def with_emissions_node
        yield if node.emissions?
      end

      # Returns the CO2 content per MJ for a specific edge.
      #
      # For edges marked with :emissions_skip_crude_oil_mix or carriers without intrinsic
      # CO2 values, delegates to RecursiveFactor::DirectEmissions to calculate from the
      # weighted supply mix. Otherwise uses the carrier's direct CO2 value.
      #
      # @return [Float] CO2 content in kg/MJ
      def direct_edge_carbon_content(edge)
       # Check if carrier has intrinsic CO2 value and edge doesn't skip it
        if edge.carrier.co2_conversion_per_mj && !edge.emissions_skip_crude_oil_mix?
          return edge.carrier.co2_conversion_per_mj
        end

        # Fallback: calculate from weighted supply mix using recursive factor
        supplier = edge.rgt_node
        supplier&.query&.direct_carbon_content_per_mj || 0.0
      end
    end
  end
end
