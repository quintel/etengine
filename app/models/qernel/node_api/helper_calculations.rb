# frozen_string_literal: true

module Qernel
  module NodeApi
    # Misc calculation methods.
    module HelperCalculations
      delegate :primary_co2_emission, to: :node

      # Public: Calculates the number of units that are installed in the future for this node, based
      # on the demand (input) of the node, the effective input capacity and the full_load_seconds of
      # the node (to effectively) convert MJ and MW
      #
      # Returns a numeric.
      def number_of_units
        dataset_get(:number_of_units) || fetch(:number_of_units, false) do
          # #to_i also checks if it is nil
          if input_capacity.nil? || input_capacity.zero? ||
              full_load_hours.nil? || full_load_hours.zero?
            0
          else
            used_capacity = input_capacity * capacity_to_demand_multiplier * full_load_hours
            (demand || preset_demand) / used_capacity
          end
        end
      end

      def number_of_units=(val)
        dataset_set(:number_of_units, val)
      end

      # Public: Returns a value representing km2 of land used by the technology.
      def total_land_use
        return nil if [number_of_units, land_use_per_unit].any?(&:nil?)

        number_of_units * land_use_per_unit
      end

      # Public: Returns the number of households which are supplied by the energy created in each
      # unit. Used in DemandDriven nodes for cases where a node may supply more than one building.
      #
      # If the dataset does not define an explicit value, this will default to 1.
      #
      # Returns the number of households supplied with energy by this node.
      def households_supplied_per_unit
        fetch(:households_supplied_per_unit) { 1.0 }
      end

      # Public: Returns a numeric.
      def sustainable_input_factor
        fetch(:sustainable_input_factor) do
          node.inputs.map { |slot| (slot.carrier.sustainable || 0.0) * slot.conversion }.compact.sum
        end
      end

      # TODO: this method returns a share. But the name presumes it is not!
      # Returns a numeric.
      def useful_output
        fetch(:useful_output) do
          [
            node.output(:electricity),
            node.output(:useable_heat),
            node.output(:steam_hot_water)
          ].map { |slot| slot and slot.conversion }.compact.sum
        end
      end

      # Public: Returns the constant by which a capacity must be multiplied to get an equivalent
      # demand.
      #
      # Molecule nodes specify capacity and demand with the same unit (kg), but energy uses MW for
      # capacity and MJ for demand.
      #
      # Returns a numeric.
      def capacity_to_demand_multiplier
        1.0
      end
    end
  end
end
