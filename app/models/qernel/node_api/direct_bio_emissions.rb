# frozen_string_literal: true

module Qernel
  module NodeApi
    # Calculates direct biogenic CO2 emissions.
    #
    # Biogenic emissions come from biomass combustion and represent carbon
    # that was recently captured from the atmosphere via photosynthesis.
    # When combined with CCS (BECCS), this creates negative emissions.
    #
    # This module parallels DirectEmissions but tracks potential_co2_conversion_per_mj
    # instead of co2_conversion_per_mj (biogenic vs fossil carbon).
    module DirectBioEmissions
      # Calculates gross direct biogenic CO2 emissions (before capture).
      #
      # @return [Float] Gross direct biogenic CO2 emission in kg
      def direct_co2_emission_of_bio_gross
        inputs.sum do |slot|
          slot.edges.sum do |edge|
            bio_carbon = direct_edge_bio_carbon_content(edge)
            (edge.net_demand || 0.0) * bio_carbon
          end
        end
      end

      # Captured direct biogenic CO2 emissions via CCS -
      # Bio CO2 from input carriers * free_co2_factor
      #
      # @return [Float] Captured direct biogenic CO2 in kg
      def direct_co2_emission_of_bio_captured
        inputs.sum do |slot|
          slot.edges.sum do |edge|
            bio_carbon = direct_edge_bio_carbon_content(edge)
            captured = bio_carbon * free_co2_factor
            (edge.net_demand || 0.0) * captured
          end
        end
      end

      # Net direct bio CO2 emissions (after capture).
      # net = gross - captured = Bio CO2 * (1 - free_co2_factor)
      #
      # @return [Float] Net direct biogenic CO2 emission in kg
      def direct_co2_emission_of_bio
        direct_co2_emission_of_bio_gross - direct_co2_emission_of_bio_captured
      end

      # Calculates the bio CO2 composition of output carriers.
      #
      # 1. For nodes with pure bio carrier values, returns the carrier value directly.
      # 2. For mixer nodes (biogas + natural gas blending), calculates weighted average
      #    of input bio compositions without output compensation.
      #
      # This method uses recursion to track bio composition through the supply chain,
      # stopping when carrier values are defined.
      #
      # @return [Float, nil] Bio CO2 composition in kg/MJ, or nil if not applicable
      def direct_output_bio_co2_composition
        return @direct_output_bio_co2_composition if defined?(@direct_output_bio_co2_composition)

        # Set sentinel to prevent infinite recursion on circular dependencies
        # TODO: this avoids relying on edges being marked 'circular' but is at odds with the implementation in recursive factor,
        # even though the outcome is the same.
        @direct_output_bio_co2_composition = 0.0

        # For nodes with carrier-defined bio values, use those
        first_output_carrier = output_edges.first&.carrier
        if first_output_carrier&.potential_co2_conversion_per_mj&.positive?
          @direct_output_bio_co2_composition = first_output_carrier.potential_co2_conversion_per_mj
          return @direct_output_bio_co2_composition
        end

        # For mixer nodes, calculate weighted average of bio inputs
        total_input = inputs.sum { |slot| slot.edges.sum(&:net_demand) }

        if total_input.zero?
          @direct_output_bio_co2_composition = nil
          return nil
        end

        @direct_output_bio_co2_composition = inputs.sum do |slot|
          slot.edges.sum do |edge|
            input_bio = direct_edge_bio_carbon_content(edge)
            input_share = edge.net_demand / total_input
            input_share * input_bio
          end
        end

        @direct_output_bio_co2_composition
      end

      private

      # List of secondary energy carriers that cannot be combusted.
      # These represent already-converted energy (electricity, heat, steam).
      # Direct emissions occur only at the combustion point (biomass CHP, biogas plant, etc.),
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

      # Returns true if carrier represents secondary energy (already converted, cannot be combusted).
      #
      # Secondary carriers like electricity and heat have already undergone energy conversion.
      # Consumers of these carriers do not combust anything and therefore have zero direct emissions.
      # Direct bio emissions are tracked at the combustion point (biomass CHP, biogas burner, etc.),
      # not at consumers of secondary energy.
      #
      # @param carrier [Carrier] The carrier to check
      # @return [Boolean] true if secondary energy carrier
      def secondary_energy_carrier?(carrier)
        SECONDARY_ENERGY_CARRIERS.include?(carrier.key)
      end

      # Returns the bio CO2 content per MJ for a specific edge.
      #
      # Strategy pattern (parallel to fossil):
      # 1. Return 0.0 for secondary carriers (electricity, heat, steam) - no combustion at consumer
      # 2. Use direct carrier bio value if defined (pure bio carriers)
      # 3. Use supplier's bio composition if carrier value is nil (mixed carriers like network_gas)
      # 4. Else return nil
      #
      # @param edge [Edge] The input edge
      # @return [Float] Bio CO2 content in kg/MJ
      def direct_edge_bio_carbon_content(edge)
        return 0.0 if secondary_energy_carrier?(edge.carrier)

        bio_co2 = edge.carrier.potential_co2_conversion_per_mj

        # If carrier has a defined bio value (including 0.0), use it directly
        # This handles pure bio carriers (biomass, biogas) and non-bio carriers
        return bio_co2 unless bio_co2.nil?

        # For carriers without defined values, check supplier's bio composition
        # This handles mixed bio/fossil carriers (e.g., network gas with biogas)
        supplier = edge.rgt_node
        if supplier&.query.respond_to?(:direct_output_bio_co2_composition)
          composition = supplier.query.direct_output_bio_co2_composition
          return composition if composition
        end

        nil # TODO: consider this case
      end
    end
  end
end
