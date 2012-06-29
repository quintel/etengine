module Qernel
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
        @calculation_units ||= {}.with_indifferent_access
        if unit
          @calculation_units[method] = unit
        else
          @calculation_units[method]
        end
      end
    end
  end
end
