# frozen_string_literal: true

module Qernel
  module Causality
    # Calculates energy conversions from one node slot to another.
    module Conversion
      # Public: Given a node, and details of two slots (carrier and
      # direction), determines how to convert energy quantities from the "from"
      # slot to the "to" slot.
      #
      # For example:
      #   Conversion.conversion(node, :electricity, :input, :heat, :output)
      #   => 0.75
      #
      # Returns a Numeric. Raises an error if a named slot is not present.
      def self.conversion(
        node,
        from_carrier,
        from_direction,
        to_carrier,
        to_direction
      )
        from = slot(node, from_carrier, from_direction).conversion
        to = slot(node, to_carrier, to_direction).conversion

        from.zero? || to.zero? ? 0.0 : to / from
      end

      def self.slot(node, carrier, direction)
        slot =
          if direction == :input
            node.input(carrier)
          else
            node.output(carrier)
          end

        slot || raise("No #{carrier} #{direction} slot on #{node.key}")
      end

      private_class_method :slot
    end
  end
end
