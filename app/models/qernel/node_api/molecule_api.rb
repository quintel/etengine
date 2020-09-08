# frozen_string_literal: true

module Qernel
  module NodeApi
    # Contains methods and attributes specific to querying molecule nodes.
    class MoleculeApi < Base
      dataset_accessors :molecule_input_capacity, :molecule_output_capacity

      # Public: Calculates the number of units, based on the demand and input or output capacity.
      #
      # Returns a numeric.
      def number_of_units
        return 0.0 if demand.zero?

        if input_capacity&.positive?
          demand / input_capacity
        elsif molecule_output_capacity&.positive?
          (demand - output_of_loss) / molecule_output_capacity
        else
          super
        end
      end

      private

      # Energy nodes use full_load_seconds in order to implicitly convert from MJ to MW, due to
      # demands being specified in MJ and capacities in MW. Molecule node units and capacities use
      # the same unit: kg.
      #
      # Returns a numeric.
      def input_capacity
        molecule_input_capacity
      end
    end
  end
end
