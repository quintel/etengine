# frozen_string_literal: true

module CurveHandler
  # An extension to the Generic handler which reduces the precision of each point in the curve to
  # two decimal places.
  class Price < Generic
    def self.presenter
      CustomPriceCurveSerializer
    end

    def sanitized_curve
      return nil unless valid?

      @curve.map do |value|
        value < 0.0 ? 0.0 : value.round(2)
      end
    end
  end
end
