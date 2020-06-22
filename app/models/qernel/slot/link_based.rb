# frozen_string_literal: true

module Qernel
  class Slot
    # A slot which calculates its conversion by looking at the demand of all the
    # links belonging to it, and determining their share of the demand of _all_
    # links in the same direction from the node.
    #
    # This is useful in cases where a graph plugin changes the flow of some of
    # the outputs, and the conversions need to be updated to ensure they remain
    # consistent with the energy flowing through them.
    #
    # This ignores any conversion set on the slot, or sibling slots, presuming
    # them to be inaccurate at the time of calculation.
    #
    # Note that a demand `value` must be known for all the links in order to
    # calculate a conversion. If some values are missing, LinkBased will fall
    # back to the behaviour of Slot.
    class LinkBased < Slot
      def conversion
        link_based_conversion || super
      end

      private

      def link_based_conversion
        fetch(:link_based_conversion, false) do
          self_and_siblings = input? ? @node.inputs : @node.outputs
          all_links = self_and_siblings.flat_map(&:links)

          return nil unless all_links.all?(&:value)

          demand = all_links.sum(&:value)
          conversion = demand.zero? ? 0.0 : @links.sum(&:value) / demand

          dataset_set(:conversion, conversion)
          dataset_set(:link_based_conversion, conversion)

          conversion
        end
      end
    end
  end
end
