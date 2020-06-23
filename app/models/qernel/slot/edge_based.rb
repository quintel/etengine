# frozen_string_literal: true

module Qernel
  class Slot
    # A slot which calculates its conversion by looking at the demand of all the
    # edges belonging to it, and determining their share of the demand of _all_
    # edges in the same direction from the node.
    #
    # This is useful in cases where a graph plugin changes the flow of some of
    # the outputs, and the conversions need to be updated to ensure they remain
    # consistent with the energy flowing through them.
    #
    # This ignores any conversion set on the slot, or sibling slots, presuming
    # them to be inaccurate at the time of calculation.
    #
    # Note that a demand `value` must be known for all the edges in order to
    # calculate a conversion. If some values are missing, EdgeBased will fall
    # back to the behaviour of Slot.
    class EdgeBased < Slot
      def conversion
        edge_based_conversion || super
      end

      private

      def edge_based_conversion
        fetch(:edge_based_conversion, false) do
          self_and_siblings = input? ? @node.inputs : @node.outputs
          all_edges = self_and_siblings.flat_map(&:edges)

          return nil unless all_edges.all?(&:value)

          demand = all_edges.sum(&:value)
          conversion = demand.zero? ? 0.0 : @edges.sum(&:value) / demand

          dataset_set(:conversion, conversion)
          dataset_set(:edge_based_conversion, conversion)

          conversion
        end
      end
    end
  end
end
