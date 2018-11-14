# frozen_string_literal: true

module Qernel::Plugins
  class TimeResolve
    module Util
      # Defines how close an amplified curve must be to the target FLH before
      # stopping iterative amplification.
      AMPLIFY_TOLERANCE = 1e-4

      module_function

      # Public: Combines two or more curves, creating a new curve where each
      # value is the sum of values in each provided curve.
      #
      # Use instead of `curves.reduce(:+)` when performance is needed.
      #
      # Returns a Merit::Curve.
      def add_curves(curves)
        case curves.length
          when 1 then curves.first
          when 2 then add_curves_2(*curves)
          when 3 then add_curves_3(*curves)
          when 4 then add_curves_4(*curves)
          when 5 then add_curves_5(*curves)
          when 10 then add_curves_10(*curves)
          when 20 then add_curves_20(*curves)
          else add_many(curves)
        end
      end

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
        ::Merit::Curve.new(chopped_curve.map { |val| val / (3600.0 * new_sum) })
      end

      # Public: Receives a curve of values and converts it to a load profile
      # which sums to 1/3600.
      #
      # Returns a Merit::Curve
      def curve_to_profile(curve)
        sum = curve.sum * 3600
        ::Merit::Curve.new(curve.map { |val| val / sum })
      end

      # Internal: Adds an arbitrary number of curves together using the largest
      # available adder methods.
      private_class_method def add_many(curves)
        while curves.length > 1
          curves = curves
            .each_slice(partition_size(curves))
            .map { |partition| add_curves(partition) }
        end

        curves.first
      end

      # Internal: Creates a method which implements loop unrolling for adding
      # two or more Merit curves. See Util.add_curves.
      #
      # Use `add_curves` as the public API to these dynamic methods.
      #
      # For example:
      #   define_curve_adder(3)
      #
      # Creates:
      #   # def add_curves_#{num_curves}(c0, c1, c2)
      #   #   ::Merit::Curve.new(Array.new(c0.length) do |index|
      #   #     c0[index] + c1[index] + c2[index]
      #   #   end)
      #   # end
      #
      # Returns the name of the generated method.
      private_class_method def define_curve_adder(num_curves)
        params = Array.new(num_curves) { |i| "c#{i}" }
        name = :"add_curves_#{num_curves}"

        param_separator = ', '.freeze
        add_separator = ' + '.freeze

        instance_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}(#{params.join(param_separator)})
            ::Merit::Curve.new(Array.new(c0.length) do |index|
              #{params.map { |p| "#{p}[index]" }.join(add_separator)}
            end)
          end
        RUBY

        name
      end

      private_class_method def partition_size(curves)
        length = curves.length

        case
          when length >= 20 then 20
          when length >= 10 then 10
          else 5
        end
      end

      private_class_method define_curve_adder(2)
      private_class_method define_curve_adder(3)
      private_class_method define_curve_adder(4)
      private_class_method define_curve_adder(5)
      private_class_method define_curve_adder(10)
      private_class_method define_curve_adder(20)
    end
  end
end
