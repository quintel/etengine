# frozen_string_literal: true

module CurveHandler
  module Processors
    # Normalizes the curve such that the the sum of the curve is 1 / 3600.
    class Profile < Generic
      def self.serializer
        CustomProfileCurveSerializer
      end

      def curve_for_storage
        return nil unless valid?

        curve = sanitized_curve
        sum = curve.sum

        return Array.new(curve.length, 0.0) if sum.zero?

        divisor = sum * 3600
        curve.map { |value| value / divisor }
      end
    end
  end
end
