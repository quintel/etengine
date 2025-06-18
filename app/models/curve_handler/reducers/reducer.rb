# frozen_string_literal: true

module CurveHandler
  module Reducers
    # Helper class for AttachService. Takes a scenario and reducer proc, allowing the curve to be
    # reduced to a single value.
    class Reducer
      # Creates a new Reducer.
      #
      # reducer   - The CurveHandler::Reducers::Reducers proc. If the proc has an arity of 2 it will be provided
      #             with both the new curve _and_ the original default curve.
      # curve_key - The name of the curve.
      # scenario  - The scenario for which the value is to be reduced.
      def initialize(reducer, curve_key, scenario)
        @reducer = reducer
        @curve_key = curve_key.to_s
        @scenario = scenario
      end

      # Receives a new curve and calculates the reduced value for the curve.
      #
      # Returns a Numeric.
      def call(curve)
        if @reducer.arity == 2
          @reducer.call(curve, default_curve)
        else
          @reducer.call(curve)
        end
      end

      private

      def default_curve
        dataset = Atlas::Dataset.find(@scenario.area_code)

        if @curve_key.include?('/')
          curve_set_name, curve_key = @curve_key.split('/', 2)
          dataset.curve_sets.get!(curve_set_name).variant!('default').curve(curve_key)
        else
          dataset.load_profile(@curve_key)
        end
      end
    end
  end
end
