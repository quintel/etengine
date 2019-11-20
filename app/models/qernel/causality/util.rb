# frozen_string_literal: true

module Qernel
  module Causality
    module Util
      # Defines how close an amplified curve must be to the target FLH before
      # stopping iterative amplification.
      AMPLIFY_TOLERANCE = 1e-4

      module_function

      # Public: Given a curve, determines the full-load hours and amplifies the
      # curve to represent a new target FLH.
      #
      # Returns a Merit::Curve.
      def amplify_curve(input_curve, target)
        curve = input_curve.to_a

        # Create a new curve representing each value as a fraction of the max.
        curve_max = curve.max
        curve = curve.map { |val| val / curve_max }
        full_load_hours = curve.sum

        if target < (full_load_hours - 1.0) ||
            (full_load_hours / target - 1.0).abs < AMPLIFY_TOLERANCE
          # Short circuit if the curve represents the same or more FLH than
          # the target.
          return input_curve.dup
        end

        chop = chop_size = 0.5
        chopped_curve = nil

        # Iterate amplifying the curve until the resulting FLH matches the
        # target. Iteratively shaves the peaks off the curve until the resulting
        # shape (when normalized) matches the target.
        30.times do
          chopped_curve = curve.map { |val| val > chop ? chop : val }
          flh = chopped_curve.sum / chop

          break if (flh / target - 1.0).abs < AMPLIFY_TOLERANCE

          # Prepare the next iteration which will add or remove only half the
          # amount of this iteration.
          chop_size /= 2.0
          chop += (flh > target ? chop_size : -chop_size)
        end

        new_sum = chopped_curve.sum

        # Normalize to describe demand in MWh.
        Merit::Curve.new(chopped_curve.map { |val| val / (3600.0 * new_sum) })
      end

      # Public: Receives a curve of values and converts it to a load profile
      # which sums to 1/3600.
      #
      # Returns a Merit::Curve
      def curve_to_profile(curve)
        sum = curve.sum * 3600
        Merit::Curve.new(curve.map { |val| val / sum })
      end
    end
  end
end
