# frozen_string_literal: true

module CurveHandler
  module Processors
    # Normalizes the curve such that the the sum of the curve is 1 / 3600.
    class Profile < Generic
      def self.presenter
        Api::V3::CustomProfileCurvePresenter
      end

      def sanitized_curve
        return nil unless valid?

        sum = @curve.sum

        return Array.new(@curve.length, 0.0) if sum.zero?

        divisor = sum * 3600
        @curve.map { |value| value / divisor }
      end
    end
  end
end
