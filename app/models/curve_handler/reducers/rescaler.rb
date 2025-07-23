module CurveHandler
  module Reducers

    class Rescaler
      # Initialize with a raw curve (Array of numeric values) and full_load_hours (Numeric).
      def initialize(raw_curve, full_load_hours)
        @curve = Array(raw_curve).map(&:to_f)
        @flh   = full_load_hours.to_f
      end

      # Returns the rescaled curve as an Array of Floats.
      # If the sum of the curve is zero, returns the original curve unchanged.
      def call
        total = @curve.sum
        return @curve if total.zero?

        multiplier = @flh / total
        @curve.map { |v| v * multiplier }
      end
    end
  end
end
