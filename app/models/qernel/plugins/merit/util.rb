# frozen_string_literal: true

module Qernel::Plugins
  module Merit
    module Util
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
          else curves.reduce(:+)
        end
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
      #   #     c0.get(index) + c1.get(index) + c2.get(index)
      #   #   end)
      #   # end
      #
      # Returns the name of the generated method.
      def define_curve_adder(num_curves)
        params = Array.new(num_curves) { |i| "c#{i}" }
        name = :"add_curves_#{num_curves}"

        param_separator = ', '.freeze
        add_separator = ' + '.freeze

        instance_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}(#{params.join(param_separator)})
            ::Merit::Curve.new(Array.new(c0.length) do |index|
              #{params.map { |p| "#{p}.get(index)" }.join(add_separator)}
            end)
          end
        RUBY

        name
      end

      private_class_method define_curve_adder(2)
      private_class_method define_curve_adder(3)
      private_class_method define_curve_adder(4)
    end
  end
end
