# frozen_string_literal: true

module Qernel
  module Causality
    # Calculates energy conversions from one converter slot to another.
    module Conversion
      # Public: Given a converter, and details of two slots (carrier and
      # direction), determines how to convert energy quantities from the "from"
      # slot to the "to" slot.
      #
      # For example:
      #   Conversion.conversion(converter, :electricity, :input, :heat, :output)
      #   => 0.75
      #
      # Returns a Numeric. Raises an error if a named slot is not present.
      def self.conversion(
        converter,
        from_carrier,
        from_direction,
        to_carrier,
        to_direction
      )
        from = slot(converter, from_carrier, from_direction).conversion
        to = slot(converter, to_carrier, to_direction).conversion

        from.zero? || to.zero? ? 0.0 : to / from
      end

      def self.slot(converter, carrier, direction)
        slot =
          if direction == :input
            converter.input(carrier)
          else
            converter.output(carrier)
          end

        slot || raise("No #{carrier} #{direction} slot on #{converter.key}")
      end

      private_class_method :slot
    end
  end
end
