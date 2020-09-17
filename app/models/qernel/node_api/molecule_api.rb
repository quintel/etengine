# frozen_string_literal: true

module Qernel
  module NodeApi
    # Contains methods and attributes specific to querying molecule nodes.
    class MoleculeApi < Base
      dataset_accessors :output_capacity

      # Public: Calculates the number of units, based on the demand and input or output capacity.
      #
      # Returns a numeric.
      def number_of_units
        return 0.0 if demand.zero?
        return super unless full_load_hours&.positive?

        if input_capacity&.positive?
          demand / (input_capacity * full_load_hours)
        elsif output_capacity&.positive?
          (demand - output_of_loss) / (output_capacity * full_load_hours)
        else
          super
        end
      end

      # Public: The price of CO2 emissions by the node. Molecule nodes do not have CO2 emissions so
      # this is always zero.
      def co2_emissions_costs_per_typical_input
        0.0
      end

      private

      # Molecule nodes define demand in kg (kg/year), while capacities are specified in kg/hour.
      #
      # Returns a numeric.
      def capacity_to_demand_multiplier
        8760.0
      end

      # The input capacity of the molecule technology.
      #
      # Returns a numeric in kg.
      def input_capacity
        typical_input_capacity
      end
    end
  end
end
