# frozen_string_literal: true

module CurveHandler
  module Reducers
    # Receives a temperature curve and the original curve, returning the different in the two
    # averages.
    Temperature = lambda do |curve, original|
      new_temp = curve.sum / curve.length
      orig_temp = original.sum / original.length

      new_temp - orig_temp
    end
  end
end
