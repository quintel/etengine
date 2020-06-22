# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Receives a Fever group and summarises the total production and
    # consumption, for use in queries, CSVs, etc.
    class Summary
      def initialize(group)
        @group  = group
        @demand = @production = @surplus = @deficit = nil
      end

      # Public: Curve of the demand for heat in each hour of the year.
      #
      # Returns an array of numerics.
      def demand
        return @demand if @demand

        suppliers =
          @group.adapters.select do |adapter|
            adapter.installed? && adapter.participant.is_a?(Fever::Consumer)
          end

        return [0.0] * 8760 if suppliers.none?

        @demand = Merit::CurveTools.add_curves(suppliers.map do |adapter|
          adapter.node.heat_input_curve
        end).to_a
      end

      # Public: Curve of the production of heat in each hour of the year.
      #
      # Returns an array of numerics.
      def production
        return @production if @production

        suppliers =
          @group.adapters.reject do |adapter|
            adapter.participant.is_a?(Fever::Consumer)
          end

        return [0.0] * 8760 if suppliers.none?

        curves =
          suppliers.map do |adapter|
            input = adapter.node.heat_input_curve
            output = adapter.node.heat_output_curve

            # Array may be empty, which means there is no curve.
            if input.first
              # In order to represent heat being produced - but stored for
              # future use - the production curve takes the maximum of the input
              # and output of each producer. This means that energy in a reserve
              # is accounted for twice. Skip this when the input and output
              # curves are the same object.
              input.map.with_index do |val, index|
                val > output[index] ? val : output[index]
              end
            else
              output.first ? output : nil
            end
          end.compact

        @production = Merit::CurveTools.add_curves(curves).to_a
      end

      # Public: A curve describing periods when production does not meet demand.
      #
      # Returns an array of numerics.
      def deficit
        calculate_surplus_and_deficit! unless @deficit
        @deficit
      end

      # Public: A curve describing periods when production exceeds demand.
      #
      # Returns an array of numerics.
      def surplus
        calculate_surplus_and_deficit! unless @surplus
        @surplus
      end

      private

      # Internal: Compares production and demand and creates two new curves
      # describing surplus and deficits.
      def calculate_surplus_and_deficit!
        @surplus = Array.new(8760)
        @deficit = Array.new(8760)

        production = self.production
        demand     = self.demand

        8760.times do |frame|
          @surplus[frame] = 0
          @deficit[frame] = 0

          diff = production[frame] - demand[frame]

          # Deficits and surpluses are rounded so as to ignore floating point
          # errors.
          if diff > 1e-6
            @surplus[frame] = diff
          elsif diff < -1e-6
            @deficit[frame] = diff.abs
          end
        end
      end
    end
  end
end
