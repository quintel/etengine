# frozen_string_literal: true

module Qernel
  module NodeApi
    # Calculations arelated to capacity and energy production.
    module CapacityProduction
      # Public: The required installed input capacity, based on the demand.
      #
      # Returns a numeric value in MWh.
      def mwh_input
        fetch(:mwh_input) { demand / SECS_PER_HOUR }
      end

      # Public: The nominal electrical capicity of one unit.
      #
      # Returns a numeric value in MW.
      def nominal_capacity_electricity_output_per_unit
        fetch(:nominal_capacity_electricity_output_per_unit) do
          input_capacity * electricity_output_conversion
        end
      end

      # Public: The nominal heat capicity of one unit. This is both useable heat as steam_hot_water.
      #
      # Returns a numeric value in MW.
      def nominal_capacity_heat_output_per_unit
        fetch(:nominal_capacity_heat_output_per_unit) do
          input_capacity * heat_output_conversion
        end
      end

      # Public: The nominal cooling capacity of one unit
      #
      # Returns a numeric value in MW.
      def nominal_capacity_cooling_output_per_unit
        fetch(:nominal_capacity_cooling_output_per_unit) do
          input_capacity * cooling_output_conversion
        end
      end

      # Public: The sum of all bio resources input.
      #
      # Returns a numeric value in MJ.
      def input_of_bio_resources
        fetch(:input_of_bio_resources) do
          input_of_dry_biomass +
            input_of_wet_biomass +
            input_of_oily_biomass +
            input_of_biogenic_waste +
            input_of_torrefied_biomass_pellets +
            input_of_wood_pellets +
            input_of_waste_mix +
            input_of_bio_kerosene +
            input_of_bio_lng +
            input_of_bio_oil +
            input_of_biodiesel +
            input_of_bio_ethanol +
            input_of_biogas +
            input_of_greengas +
            input_of_network_gas +
            input_of_compressed_network_gas +
            input_of_gas_power_fuelmix
        end
      end

      # Public: The sum of all bio fuels input. This is biodiesel, bio kerosene, bio oil, bio lng,
      # and bio ethanol.
      #
      # Returns a numeric value in MJ.
      def input_of_bio_fuels
        fetch(:input_of_bio_fuels) do
          input_of_biodiesel +
            input_of_bio_kerosene +
            input_of_bio_oil +
            input_of_bio_lng +
            input_of_bio_ethanol
        end
      end

      # Public: The total heat output conversion of one unit. This is useable heat and
      # steam_hot_water.
      #
      # Returns a numeric value.
      def heat_output_conversion
        fetch(:heat_output_conversion) do
          (steam_hot_water_output_conversion + useable_heat_output_conversion)
        end
      end

      # Public: The total heat and cold output conversion of one unit. This is useable heat,
      # steam_hot_water, and cooling.
      #
      # Returns a numeric value.
      def heat_and_cold_output_conversion
        fetch(:heat_and_cold_output_conversion) do
          steam_hot_water_output_conversion +
            useable_heat_output_conversion +
            cooling_output_conversion
        end
      end

      def coefficient_of_performance
        fetch(:coefficient_of_performance) do
          if fever&.efficiency_based_on && fever&.efficiency_balanced_with
            # When a Fever participant defines which carriers are used by a heat pump, use these
            # rather than guessing.
            heat_pump_coefficient_of_performance
          else
            non_ambient_share = 1 - (
              ambient_heat_input_conversion +
              ambient_cold_input_conversion +
              geothermal_input_conversion +
              solar_thermal_input_conversion
            )

            non_ambient_share <= 0 ? 1.0 : 1 / non_ambient_share
          end
        end
      end

      # Public: How many seconds a year the node runs at full load. This is useful because MJ is MW
      # per second.
      #
      # Returns a numeric.
      def full_load_seconds
        full_load_hours * SECS_PER_HOUR
      end

      # Public: Calculates the total electricity production of the node, based on the value per unit
      # and the number of units.
      #
      # Returns a numeric value in MJ.
      def production_based_on_number_of_units
        fetch(:production_based_on_number_of_units) do
          number_of_units * typical_electricity_production_per_unit
        end
      end

      # Public: Calculates the total hydrogen production of the node, based on the value per unit
      # and the number of units.
      #
      # Returns a numeric value in MJ.
      def hydrogen_production_based_on_number_of_units
        fetch(:hydrogen_production_based_on_number_of_units) do
          number_of_units * typical_hydrogen_production_per_unit
        end
      end

      # Public: Calculates the total ammonia production of the node, based on the value per unit
      # and the number of units.
      #
      # Returns a numeric value in MJ.
      def ammonia_production_based_on_number_of_units
        fetch(:ammonia_production_based_on_number_of_units) do
          number_of_units * typical_ammonia_production_per_unit
        end
      end

      # Public: Calculates the electricity output capacity based on the output conversion and total
      # input capacity of the node.
      #
      # Returns a numeric value in MW.
      def typical_electricity_production_capacity
        fetch(:typical_electricity_production_capacity) do
          electricity_output_conversion * input_capacity
        end
      end

      # Public: Calculates the hydrogen output capacity based on the output conversion and total
      # input capacity of the node.
      #
      # Returns a numeric value in MW.
      def typical_hydrogen_production_capacity
        fetch(:typical_hydrogen_production_capacity) do
          hydrogen_output_conversion * input_capacity
        end
      end

      # Public: Calculates the ammmonia output capacity based on the output conversion and total
      # input capacity of the node.
      #
      # Returns a numeric value in MW.
      def typical_ammonia_production_capacity
        fetch(:typical_ammonia_production_capacity) do
          ammonia_output_conversion * input_capacity
        end
      end

      # Public: Calculates the electricity production of one unit of the technology.
      #
      # Returns a numeric value in MJ.
      def typical_electricity_production_per_unit
        fetch(:typical_electricity_production_per_unit) do
          typical_electricity_production_capacity * full_load_seconds
        end
      end

      # Public: Calculates the hydrogen production of one unit of the technology.
      #
      # Returns a numeric value in MJ.
      def typical_hydrogen_production_per_unit
        fetch(:typical_hydrogen_production_per_unit) do
          typical_hydrogen_production_capacity * full_load_seconds
        end
      end

      # Public: Calculates the ammonia production of one unit of the technology.
      #
      # Returns a numeric value in MJ.
      def typical_ammonia_production_per_unit
        fetch(:typical_ammonia_production_per_unit) do
          typical_ammonia_production_capacity * full_load_seconds
        end
      end

      # Public: Calculates the maximum amount of electricity which can be produced in a single unit
      # of the technology.
      #
      # Returns a numeric value in MJ.
      def maximum_yearly_electricity_production_per_unit
        fetch(:typical_electricity_production_per_unit) do
          typical_electricity_production_capacity * availability * 8760 * 3600
        end
      end

      # Public: Calculates the total electricity output capacity of the node.
      #
      # Returns a numeric value in MW.
      def installed_production_capacity_in_mw_electricity
        fetch(:installed_production_capacity_in_mw_electricity) do
          electricity_output_conversion * input_capacity * number_of_units
        end
      end

      alias_method :electricity_production_in_mw, :installed_production_capacity_in_mw_electricity

      # Public: The MW power that is consumed by an electricity consuming technology.
      #
      # Returns a numeric value in MW.
      def mw_power
        fetch(:mw_power) do
          full_load_seconds == 0.0 ? 0.0 : demand / full_load_seconds
        end
      end

      # The MW input capacity of a (electricity producing) technology NOTE: this function is
      # identical to mw_power (defined above) power is a more precise name if we talk about the
      # actually consumed MWs capacity is the maximal power and therefore more appropriate to
      # calculate the output of electricity generating technologies.
      alias_method :mw_input_capacity, :mw_power

      # Heat

      # Public: Calculates the maximum amount of heat which can be produced by the node.
      #
      # NOTE: disabled caching - Fri 29 Jul 2011 16:36:49 CEST
      #       - Fixed attributes_required_for and use handle_nil instead. SB - Thu 25. Aug 11
      #
      # Returns a value in MJ.
      def production_based_on_number_of_heat_units
        if number_of_units && typical_heat_production_per_unit
          number_of_units * typical_heat_production_per_unit
        end
      end

      # Public: Calculates the amount of heat which is produced by a single unit.
      #
      # Returns a value in MJ.
      def typical_heat_production_per_unit
        heat_output_conversion * input_capacity * full_load_seconds if input_capacity
      end

      # Public: Returns the electricity output capacity of the node.
      #
      # If no value is assigned in the ETSource data, a capacity will attempt to be derived from the
      # `typical_input_capacity`. Note that we do not call `input_capacity` and instead rely on the
      # typical capacity, as `input_capacity` may itself call `electricity_output_capacity`.
      def electricity_output_capacity
        fetch(:electricity_output_capacity, false) do
          typical_input_capacity ? typical_input_capacity * electricity_output_conversion : 0.0
        end
      end

      # Public: Returns the heat output capacity of the node.
      #
      # If no value is assigned in the ETSource data, a capacity will attempt to be derived from the
      # `typical_input_capacity`. Note that we do not call `input_capacity` and instead rely on the
      # typical capacity, as `input_capacity` may itself call `heat_output_capacity`.
      def heat_output_capacity
        fetch(:heat_output_capacity, false) do
          typical_input_capacity ? typical_input_capacity * heat_output_conversion : 0.0
        end
      end

      # Public: Returns the hydrogen output capacity of the node.
      #
      # If no value is assigned in the ETSource data, a capacity will attempt to be derived from the
      # `typical_input_capacity`. Note that we do not call `input_capacity` and instead rely on the
      # typical capacity, as `input_capacity` may itself call `hydrogen_output_capacity`.
      def hydrogen_output_capacity
        fetch(:hydrogen_output_capacity, false) do
          typical_input_capacity ? typical_input_capacity * hydrogen_output_conversion : 0.0
        end
      end

      private

      # Internal: Calculates the coefficienct of performance
      def heat_pump_coefficient_of_performance
        secondary_carriers = inputs.map { |input| input.carrier.key } -
          [fever.efficiency_based_on, fever.efficiency_balanced_with]

        primary_carrier = input(fever.efficiency_based_on)
        secondary_conversions = secondary_carriers.sum { |carrier| input(carrier).conversion }

        if primary_carrier.conversion.zero?
          1.0
        else
          (1 - secondary_conversions) / primary_carrier.conversion
        end
      end
    end
  end
end
