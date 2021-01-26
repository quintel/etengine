# frozen_string_literal: true

module CurveHandler
  module Reducers
    FullLoadHours = lambda do |curve|
      sum = curve.sum

      if curve.empty? || sum.zero?
        0.0
      else
        (sum * (8760.0 / curve.length)).clamp(0.0, 8760.0)
      end
    end
  end
end
