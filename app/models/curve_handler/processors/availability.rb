# frozen_string_literal: true

module CurveHandler
  module Processors
    # Handles a curve where each value represents the availability of a producer or consumer. Each
    # value is between 0 and 1.
    class Availability < Generic
      # Public: Processes the curve to clamp all values to 0..1.
      def sanitized_curve
        return nil unless valid?

        @sanitized_curve ||= @curve.map { |value| value.clamp(0.0, 1.0) }
      end
    end
  end
end
