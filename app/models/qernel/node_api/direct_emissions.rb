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
          sum_carbon_content(inputs.flat_map(&:edges), :fossil)
        end
      end

      # CO2 content of all carriers leaving the node (C).
      #
      # @return [Float, nil] Total CO2 content from output carriers in kg, or nil if node is not in emissions group
      def direct_co2_output_content_carriers_fossil
        with_emissions_node do
          sum_carbon_content(output_edges, :fossil)
        end
      end

      # CO2 emissions produced at this node (E).
      # TODO: extend once capture is included.
      #
      # Calculates net emissions after accounting for CO2 utilisation.
      # Mass balance equation: Emissions = input co2 + utilised co2 - output co2
      #
      # @return [Float, nil] Direct fossil CO2 emissions in kg, or nil if node is not in emissions group
      def direct_co2_output_production_emissions_fossil
        with_emissions_node do
          direct_co2_input_content_carriers_fossil      +
            direct_co2_input_utilisation_fossil         -
            direct_co2_output_production_capture_fossil -
            direct_co2_output_content_carriers_fossil
        end
      end

      # Biogenic CO2 content of all carriers entering the node (A).
      #
      # @return [Float, nil] Total biogenic CO2 content from input carriers in kg, or nil if node is not in emissions group
      def direct_co2_input_content_carriers_biogenic
        with_emissions_node do
          sum_carbon_content(inputs.flat_map(&:edges), :biogenic)
        end
      end

      # Biogenic CO2 content of all carriers leaving the node (C).
      #
      # @return [Float, nil] Total biogenic CO2 content from output carriers in kg, or nil if node is not in emissions group
      def direct_co2_output_content_carriers_biogenic
        with_emissions_node do
          sum_carbon_content(output_edges, :biogenic)
        end
      end

      # Biogenic CO2 emissions produced at this node (E).
      #
      # @return [Float, nil] Direct biogenic CO2 emissions in kg, or nil if node is not in emissions group
      def direct_co2_output_production_emissions_biogenic
        with_emissions_node do
          direct_co2_input_content_carriers_biogenic      -
            direct_co2_output_production_capture_biogenic -
            direct_co2_output_content_carriers_biogenic
        end
      end

      # Fossil CO2 captured at this node.
      #
      # Calculates the amount of fossil CO2 captured based on the mass balance
      # (A + B - C) multiplied by the CCS capture rate.
      #
      # @return [Float, nil] Fossil CO2 captured in kg, or nil if node is not in emissions group
      def direct_co2_output_production_capture_fossil
        with_emissions_node do
          calculate_capture(
            direct_co2_input_content_carriers_fossil +
              direct_co2_input_utilisation_fossil -
              direct_co2_output_content_carriers_fossil
          )
        end
      end

      # Biogenic CO2 captured at this node.
      #
      # Calculates the amount of biogenic CO2 captured based on the mass balance
      # (A - C) multiplied by the CCS capture rate.
      #
      # @return [Float, nil] Biogenic CO2 captured in kg, or nil if node is not in emissions group
      def direct_co2_output_production_capture_biogenic
        with_emissions_node do
          calculate_capture(
            direct_co2_input_content_carriers_biogenic -
              direct_co2_output_content_carriers_biogenic
          )
        end
      end

      # Fossil CO2 utilised (consumed as feedstock) at this node.
      #
      # Calculates CO2 that is consumed as feedstock rather than emitted, based on the total
      # output energy and the node's co2_utilisation_per_mj attribute.
      #
      # @return [Float, nil] Total fossil CO2 utilised in kg, or nil if node is not in emissions group
      def direct_co2_input_utilisation_fossil
        with_emissions_node do
          total_output_energy = output_edges.sum { |edge| edge.net_demand || 0.0 }
          utilisation_rate = dataset_get(:co2_utilisation_per_mj) || 0.0
          total_output_energy * utilisation_rate
        end
      end

      # Total CO2 utilised (consumed as feedstock) at this node.
      #
      # Currently returns only fossil utilisation, as biogenic utilisation is always 0.
      #
      # @return [Float, nil] Total CO2 utilised in kg, or nil if node is not in emissions group
      def direct_co2_input_utilisation
        with_emissions_node do
          direct_co2_input_utilisation_fossil
          # Potentially in the future: + direct_co2_input_utilisation_biogenic (currently 0)
        end
      end

      # Reporting Methods -------------------------------------------------------------------------------

      # The GHG carrier type for this node: 'Other GHG' for molecule nodes whose input slot
      # carries other_ghg, 'CO2' for all others (energy nodes always emit CO2).
      #
      # @return [String] 'Other GHG' or 'CO2'
      def ghg_carrier
        inputs.map { |s| s.carrier&.key }.include?(:other_ghg) ? 'Other GHG' : 'CO2'
      end

      # Fossil CO2 production at this node
      #
      # Input content + utilisation - output co2 content
      #
      # @return [Float, nil] Direct fossil CO2 production in kg, or nil if node is not in emissions group
      def direct_reporting_emissions_co2_production
        with_emissions_node do
          direct_co2_input_content_carriers_fossil  +
            direct_co2_input_utilisation_fossil     -
            direct_co2_output_content_carriers_fossil
        end
      end

      # Total CO2 captured at this node.
      #
      # Sum of fossil and biogenic capture.
      #
      # @return [Float, nil] Total CO2 captured in kg, or nil if node is not in emissions group
      def direct_reporting_emissions_co2_capture
        with_emissions_node do
          direct_co2_output_production_capture_fossil +
          direct_co2_output_production_capture_biogenic
        end
      end

      # Other GHG emissions (non-CO2) at this node.
      #
      # Currently returns 0 as a placeholder
      #
      # @return [Float, nil] Other GHG emissions in kg CO2-equivalent, or nil if node is not in emissions group
      def direct_reporting_emissions_other_ghg_emissions
        with_emissions_node do
          0.0
        end
      end

      # Total GHG emissions at this node.
      #
      # Total co2 and other_ghg emissions - capture
      #
      # @return [Float, nil] Total GHG emissions in kg, or nil if node is not in emissions group
      def direct_reporting_emissions_total_ghg_emissions
        with_emissions_node do
          direct_reporting_emissions_co2_production -
            direct_reporting_emissions_co2_capture  +
            direct_reporting_emissions_other_ghg_emissions
        end
      end

      private

      # Yields the given block only if the node belongs to the :emissions group.
      #
      # @return [Float, nil] Result of the block, or nil if node is not in emissions group
      def with_emissions_node
        yield if node.emissions?
      end

      # Sums carbon content across multiple edges.
      #
      # @param edges [Array<Edge>] The edges to sum carbon content for
      # @param carbon_type [Symbol] Either :fossil or :biogenic
      # @return [Float] Total carbon content in kg
      def sum_carbon_content(edges, carbon_type)
        edges.sum do |edge|
          carbon_content = direct_edge_carbon_content(edge, carbon_type)
          (edge.net_demand || 0.0) * carbon_content
        end
      end

      # Returns the CO2 content per MJ for a specific edge.
      #
      # For edges marked with :emissions_skip_crude_oil_mix or carriers without intrinsic
      # CO2 values, delegates to RecursiveFactor::DirectEmissions to calculate from the
      # weighted supply mix. Otherwise uses the carrier's direct CO2 value.
      #
      # @param edge [Edge] The edge to calculate carbon content for
      # @param carbon_type [Symbol] Either :fossil or :biogenic
      # @return [Float] CO2 content in kg/MJ
      def direct_edge_carbon_content(edge, carbon_type)
        attribute, fallback_method = carbon_type_attributes(carbon_type)

        # Check if carrier has intrinsic CO2 value and edge doesn't skip it
        if edge.carrier.public_send(attribute) && !edge.emissions_skip_crude_oil_mix?
          return edge.carrier.public_send(attribute)
        end

        # Fallback: calculate from weighted supply mix using recursive factor
        supplier = edge.rgt_node
        supplier&.query&.public_send(fallback_method) || 0.0
      end

      # Calculates the amount of CO2 captured based on the CCS capture rate.
      #
      # @param co2_production [Float] The amount of CO2 available for capture
      # @return [Float] Amount of CO2 captured in kg
      def calculate_capture(co2_production)
        if (capture_rate = node.dataset_get(:ccs_capture_rate))&.positive?
          co2_production * capture_rate
        else
          0.0
        end
      end

      # Maps carbon type to carrier attribute and query method names.
      #
      # @param carbon_type [Symbol] Either :fossil or :biogenic
      # @return [Array<Symbol>] [carrier_attribute, query_method]
      def carbon_type_attributes(carbon_type)
        case carbon_type
        when :fossil
          [:co2_conversion_per_mj, :direct_carbon_content_per_mj]
        when :biogenic
          [:potential_co2_conversion_per_mj, :direct_biogenic_carbon_content_per_mj]
        else
          raise ArgumentError, "Unknown carbon type: #{carbon_type}"
        end
      end
    end
  end
end
