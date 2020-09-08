# frozen_string_literal: true

module Qernel
  module NodeApi
    # Contains methods and attributes specific to querying molecule nodes.
    class MoleculeApi < Base
      dataset_accessors :molecule_input_capacity, :molecule_output_capacity

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
