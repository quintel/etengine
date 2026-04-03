# frozen_string_literal: true

module Qernel
  module NodeApi
    # Calculates direct CO2 emissions from fossil fuels.
    #
    # Direct emissions measure the change in carbon stock at a specific node:
    # - Carbon enters via input carriers
    # - Carbon leaves via output carriers or emissions
    # - Direct emissions = CO2 released to atmosphere at this location
    #
    # For mixed carriers (network gas, crude oil, carrier_mix), this module
    # recursively tracks composition through the supply chain.
    module DirectEmissions
      # Calculates gross direct fossil CO2 emissions (before capture).
      #
      # @return [Float] Gross direct fossil CO2 emission in kg
      def direct_co2_emission_of_fossil_gross
        inputs.sum do |slot|
          slot.edges.sum do |edge|
            carbon_content = direct_edge_carbon_content(edge)
            (edge.net_demand || 0.0) * carbon_content
          end
        end
      end

      # The fossil CO2 portion of "CO2 capture" - CO2 from input carriers * free_co2_factor
      #
      # @return [Float] Captured direct fossil CO2 in kg
      def direct_co2_emission_of_fossil_captured
        inputs.sum do |slot|
          slot.edges.sum do |edge|
            carbon_content = direct_edge_carbon_content(edge)
            captured = carbon_content * free_co2_factor
            (edge.net_demand || 0.0) * captured
          end
        end
      end

      # Net direct fossil CO2 emissions (after capture).
      # net = gross - captured = CO2 * (1 - free_co2_factor)
      #
      # @return [Float] Net direct fossil CO2 emission in kg
      def direct_co2_emission_of_fossil
        direct_co2_emission_of_fossil_gross - direct_co2_emission_of_fossil_captured
      end

      # Calculates the CO2 composition of output carriers
      #
      # 1. For nodes with pure carrier values, returns the carrier value directly.
      # 2. For mixer nodes (e.g. network gas), calculates weighted average of input compositions without output compensation.
      #
      # This method uses recursion to track composition through the supply chain,
      # stopping when carrier values are defined.
      #
      # @return [Float, nil] CO2 composition in kg/MJ, or nil if not applicable
      def direct_output_co2_composition
        return @direct_output_co2_composition if defined?(@direct_output_co2_composition)

        # Set sentinel to prevent infinite recursion on circular dependencies
        # TODO: this avoids relying on edges being marked 'circular' but is at odds with the implementation in recursive factor,
        # even though the outcome is the same. Assess/discuss
        @direct_output_co2_composition = 0.0

        # For nodes with carrier-defined values, use those
        first_output_carrier = output_edges.first&.carrier
        if first_output_carrier&.co2_conversion_per_mj&.positive?
          @direct_output_co2_composition = first_output_carrier.co2_conversion_per_mj
          return @direct_output_co2_composition
        end

        # For mixer nodes, calculate weighted average of inputs
        total_input = inputs.sum { |slot| slot.edges.sum(&:net_demand) }

        if total_input.zero?
          @direct_output_co2_composition = nil
          return nil
        end

        @direct_output_co2_composition = inputs.sum do |slot|
          slot.edges.sum do |edge|
            input_carbon = direct_edge_carbon_content(edge)
            input_share = edge.net_demand / total_input
            input_share * input_carbon
          end
        end

        @direct_output_co2_composition
      end

      private

      # List of secondary energy carriers that cannot be combusted.
      # These represent already-converted energy (electricity, heat, steam).
      # Direct emissions occur only at the combustion point (coal plant, biomass CHP, etc.),
      # not at the consumer of secondary energy.
      SECONDARY_ENERGY_CARRIERS = %i[
        electricity
        steam_hot_water
        hot_water
        useable_heat
        residual_heat
        imported_electricity
        imported_heat
      ].freeze

      # Returns true if carrier represents secondary energy
      def secondary_energy_carrier?(carrier)
        SECONDARY_ENERGY_CARRIERS.include?(carrier.key)
      end

      # Returns the CO2 content per MJ for a specific edge.
      #
      # Strategy pattern:
      # 1. Return 0.0 for secondary carriers (electricity, heat, steam) - no combustion at consumer
      # 2. Use direct carrier value if defined (pure fossil carriers)
      # 3. Use supplier's composition if carrier value is nil (mixed carriers like network_gas)
      # 4. Else return nil
      #
      # @return [Float] CO2 content in kg/MJ
      def direct_edge_carbon_content(edge)
        return 0.0 if secondary_energy_carrier?(edge.carrier)

        carrier_co2 = edge.carrier.co2_conversion_per_mj

        # If carrier has a defined value (including 0.0), use it directly
        # This handles pure fossil carriers (coal, natural_gas, etc.)
        return carrier_co2 unless carrier_co2.nil?

        # For carriers without defined values, check supplier's composition
        # This handles mixed carriers (network_gas)
        supplier = edge.rgt_node
        if supplier&.query.respond_to?(:direct_output_co2_composition)
          composition = supplier.query.direct_output_co2_composition
          return composition if composition
        end

        0.0
      end
    end
  end
end
