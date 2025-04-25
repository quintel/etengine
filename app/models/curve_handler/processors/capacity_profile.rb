# frozen_string_literal: true

module CurveHandler
  module Processors
    # Normalizes the curve such that the the sum of the curve is 1 / 3600.
    class CapacityProfile < Profile

      def self.serializer
        CustomCapacityProfileCurveSerializer
      end

      # Public: Processes the curve to clamp all values to 0..1.
      def sanitized_curve
        return nil unless valid?

        @sanitized_curve ||= @curve.map { |value| value.clamp(0.0, 1.0) }
      end
    end
  end
end
