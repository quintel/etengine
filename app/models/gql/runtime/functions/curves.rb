# frozen_string_literal: true

module Gql::Runtime
  module Functions
    # Contains GQL functions for retrieving and manipulating curves.
    module Curves
      # Public: Looks up the attachment matching the `name`, and returns a Merit::Curve.
      # If no attachment is set, nil is returned.
      def ATTACHED_CURVE(name)
        return unless scope.gql.scenario.attached_curve?(name.to_s)

        scope.gql.scenario.attached_curve(name.to_s).curve&.to_a
      end

      # Public: Restricts the values in a curve to be between the minimum and maximum. Raises an
      # error if min > max.
      #
      # Returns an array.
      def CLAMP_CURVE(curve, min, max)
        unless min.is_a?(Numeric)
          raise ArgumentError, "CLAMP_CURVE: min must be numeric, was #{min.inspect}"
        end

        unless max.is_a?(Numeric)
          raise ArgumentError, "CLAMP_CURVE: max must be numeric, was #{max.inspect}"
        end

        if min >= max
          raise ArgumentError, "CLAMP_CURVE: min must be less than max, was #{min} > #{max}"
        end

        return [] if curve.blank?

        curve.map { |value| value.clamp(min, max) }
      end

      # Public: If the given `curve` is an array of non-zero length, it is
      # returned. If the curve is nil or empty, a new curve of `length` length
      # is created, with each value set to `default`.
      def COALESCE_CURVE(curve, default = 0.0, length = 8760)
        curve&.any? ? curve : [default] * length
      end

      # Public: Creates a new curve where each index (n) is the sum of (0..n) in the source curve.
      #
      # Returns an array.
      def CUMULATIVE_CURVE(curve)
        output = Array.new(curve.length)
        running_total = 0.0

        curve.each.with_index do |val, index|
          output[index] = (running_total += val)
        end

        output
      end

      # Inverts a single curve by swapping positive numbers to be negative, and
      # vice-versa.
      #
      # Returns an array.
      def INVERT_CURVE(curve)
        return [] if curve.nil? || curve == 0.0

        curve.map(&:-@)
      end

      # Adds the values in multiple curves.
      #
      # For example:
      #   SUM_CURVES([1, 2], [3, 4]) # => [4, 6]
      #   SUM_CURVES([[1, 2], [3, 4]]) # => [4, 6]
      #
      # Returns an array.
      def SUM_CURVES(*curves)
        if curves.length == 1 && curves.first
          # Was given a single number; this is typically the result of calling `V(obj, attr)` on
          # an `obj` which doesn't eixst.
          return [] if curves.first == 0.0

          unless curves.first.first.is_a?(Numeric)
            # Was given an array of curves as the sole argument.
            curves = curves.first
          end
        end

        curves = curves.compact
        return [] if curves.none?

        return curves.first.to_a if curves.one?

        Merit::CurveTools.add_curves(curves).to_a
      end

      # Public: Multiplies two curves elementwise.
      #
      # For example:
      #   PRODUCT_CURVES([1, 2, 3], [4, 5, 6])
      #   # => [4, 10, 18]
      #
      # Note that unlike `SUM_CURVES`, `PRODUCT_CURVES` expects exactly two arguments, each one a
      # single curve.
      #
      # An error will be raised if either parameter is an array of curves, or if the curves don't
      # have matching lengths.
      #
      # Returns an array of numerics.
      def PRODUCT_CURVES(left, right)
        with_elementwise_curves('PRODUCT_CURVES', left, right) do
          left.map.with_index { |value, index| value * right[index] }
        end
      end

      # Public: Divides two curves elementwise.
      #
      # For example:
      #   DIVIDE_CURVES([1, 2, 3], [4, 5, 6])
      #   # => [0.25, 0.4, 0.5]
      #
      # Note that unlike `SUM_CURVES`, `DIVIDE_CURVES` expects exactly two arguments, each one a
      # single curve.
      #
      # An error will be raised if either parameter is an array of curves, or if the curves don't
      # have matching lengths.
      #
      # Returns an array of numerics.
      def DIVIDE_CURVES(left, right)
        with_elementwise_curves('DIVIDE_CURVES', left, right) do
          left.map.with_index do |value, index|
            right[index].zero? ? 0.0 : value.to_f / right[index]
          end
        end
      end

      # Creates a smoothed curve using a moving average.
      #
      # curve       - An array of numbers.
      # window_size - The number of points to average over.
      #
      # Returns an array of numerics.
      def SMOOTH_CURVE(curve, window_size)
        return [] if curve.blank?

        window_size = [window_size, curve.length].min.to_i
        half_window = window_size / 2

        curve_with_window = curve[-half_window..] + curve + curve[0..half_window]
        sum = curve_with_window[0...window_size].sum.to_f

        Array.new(curve.length) do |index|
          value = sum / window_size

          sum += curve_with_window[index + window_size]
          sum -= curve_with_window[index]

          value
        end
      end

      private

      def with_elementwise_curves(caller_name, left, right)
        return [] if left.blank? || right.blank?

        if (left_invalid = left.first.is_a?(Array)) || right.first.is_a?(Array)
          raise "#{caller_name} can only multiply a single curve with a single curve " \
                "(#{left_invalid ? 'first' : 'second'} parameter had " \
                "#{(left_invalid ? left : right).length} nested curves)"
        end

        if left.length != right.length
          raise "Mismatch in curve lengths given to #{caller_name} " \
                "(got #{left.length} and #{right.length})"
        end

        yield
      end
    end
  end
end
