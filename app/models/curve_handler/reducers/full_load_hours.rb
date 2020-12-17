# frozen_string_literal: true

module CurveHandler
  module Reducers
    FullLoadHours = lambda do |curve|
      max = curve.max

      if curve.empty? || max.zero?
        0.0
      else
        hours_per_el = 8760.0 / curve.length
        curve.sum { |value| value / max } * hours_per_el
      end
    end
  end
end
