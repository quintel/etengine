# frozen_string_literal: true

module Qernel
  # Provides the "unit_for_calculation" helper, which allows developers to describe the unit of the
  # number returned by a calculation. This may be displayed in the front-end.
  module CalculationUnits
    extend ActiveSupport::Concern

    module ClassMethods
      # sets and gets a calculation unit
      #
      #
      # unit_for_calculation :foo, :bar
      # - sets the unit
      #
      # unit_for_calculation :foo
      # - gets the unit
      #
      def unit_for_calculation(method, unit = nil)
        method = method.to_sym

        return calculation_units[method] = unit if unit
        return calculation_units[method] if calculation_units[method]

        # Current class does not have a value. Check ancestors.
        ancestors.each do |ancestor|
          next if ancestor == self || !ancestor.respond_to?(:calculation_units)

          value = ancestor.calculation_units[method]
          return value if value
        end

        nil
      end

      def calculation_units
        @calculation_units ||= {}
      end
    end
  end
end
