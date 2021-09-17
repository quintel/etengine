# frozen_string_literal: true

module Gql::Runtime
  module Functions
    # Contains GQL functions for retrieving and manipulating curves.
    module Curves
      # Public: Looks up the attachment matching the `name`, and converts the
      # contents into a curve. If no attachment is set, nil is returned.
      def ATTACHED_CURVE(name)
        name = name.to_s
        scenario = scope.gql.scenario

        return nil unless scenario.attachment?(name)

        path = ActiveStorage::Blob.service.path_for(scenario.attachment(name).file.key)

        # The graph wants an array. Loading a curve and converting to an array
        # is expensive since Merit::Curve has to deal with the possibility of
        # missing/default values. Using the reader directly avoids this
        # overhead.
        Merit::Curve.reader.read(path)
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
        return [] if left.blank? || right.blank?

        if (left_invalid = left.first.is_a?(Array)) || right.first.is_a?(Array)
          raise 'PRODUCT_CURVES can only multiply a single curve with a single curve ' \
                "(#{left_invalid ? 'first' : 'second'} parameter had " \
                "#{(left_invalid ? left : right).length} nested curves)"
        end

        if left.length != right.length
          raise 'Mismatch in curve lengths given to PRODUCT_CURVES ' \
                "(got #{left.length} and #{right.length})"
        end

        left.map.with_index { |value, index| value * right[index] }
      end
    end
  end
end
