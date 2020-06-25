# frozen_string_literal: true

module Qernel
  class NodeApi
    # Misc calculation methods.
    module HelperCalculations
      include CalculationUnits

      delegate :primary_co2_emission, to: :node

      # Calculates the number of units that are installed in the future for this node, based on the
      # demand (input) of the node, the effective input capacity and the full_load_seconds of the
      # node (to effectively) convert MJ and MW
      def number_of_units
        dataset_get(:number_of_units) || fetch(:number_of_units, false) do
          # #to_i also checks if it is nil
          if input_capacity.nil? || input_capacity.zero? ||
              full_load_seconds.nil? || full_load_seconds.zero?
            0
          else
            (demand || preset_demand) / (input_capacity * full_load_seconds)
          end
        end
      end
      unit_for_calculation 'number_of_units', 'number'

      def number_of_units=(val)
        dataset_set(:number_of_units, val)
      end

      def total_land_use
        return nil if [number_of_units, land_use_per_unit].any?(&:nil?)

        number_of_units * land_use_per_unit
      end
      unit_for_calculation 'total_land_use', 'km2'

      # Returns the number of households which are supplied by the energy created in each unit. Used
      # in DemandDriven nodes for cases where a node may supply more than one building.
      #
      # If the dataset does not define an explicit value, this will default to 1.
      #
      # Returns the number of households supplied with energy by this node.
      def households_supplied_per_unit
        fetch(:households_supplied_per_unit) { 1.0 }
      end

      def sustainable_input_factor
        fetch(:sustainable_input_factor) do
          node.inputs.map { |slot| (slot.carrier.sustainable || 0.0) * slot.conversion }.compact.sum
        end
      end
      unit_for_calculation 'sustainable_input_factor', 'factor'

      # TODO: this method returns a share. But the name presumes it is not!
      def useful_output
        fetch(:useful_output) do
          [
            node.output(:electricity),
            node.output(:useable_heat),
            node.output(:steam_hot_water)
          ].map { |slot| slot and slot.conversion }.compact.sum
        end
      end
      unit_for_calculation 'useful_output', 'factor'
    end
  end
end
