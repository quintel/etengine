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
            carbon_content = edge.carrier.co2_conversion_per_mj || 0.0
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
        return nil unless node.groups.include?(:emissions)
        yield
      end

      # Returns the CO2 content per MJ for a specific edge.
      #
      # 1. Use direct carrier value if defined (pure fossil carriers)
      # 2. Use RecursiveFactor's weighted composition for mixed carriers (network_gas, etc.)
      # 3. Return 0.0 if neither is available
      #
      # @return [Float] CO2 content in kg/MJ
      def direct_edge_carbon_content(edge)
        carrier_co2 = edge.carrier.co2_conversion_per_mj

        # If carrier has a defined value (including 0.0), use it directly
        # This handles pure fossil carriers (coal, natural_gas, etc.)
        return carrier_co2 unless carrier_co2.nil?

        supplier = edge.rgt_node
        supplier&.query&.weighted_carrier_co2_per_mj || 0.0
      end
    end
  end
end
