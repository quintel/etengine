module Qernel::Plugins
  module Hydrogen
    class Calculator
      def initialize(demand, supply)
        @demand = demand
        @supply = supply

        @import = [0.0] * 8760
        @export = [0.0] * 8760
      end

      def inspect
        "#<#{self.class} demand=#{total_demand.sum} supply=#{total_supply.sum}>"
      end

      # Public: Curve summing demand and exports.
      def total_demand
        @demand.zip(@export).map(&:sum)
      end

      # Public: Curve summing supply and imports.
      def total_supply
        @supply.zip(@import).map(&:sum)
      end

      # Public: Given a demand and supply curve, creates a new curve describing the
      # excess of demand (positive) or of supply (negative).
      def residual_demand
        total_demand.map(&:-@).zip(total_supply).map(&:sum)
      end

      # Public: Given a curve creates a new curve where each value is the sum of
      # itself plus the previous cumulative value.
      def cumulative_residual_demand
        curve = residual_demand
        cumulative = []

        curve.each.with_index do |value, index|
          cumulative.push(index.zero? ? value : value + cumulative[index - 1])
        end

        cumulative
      end

      def storage_in
        residual_demand.map { |v| v.positive? ? v : 0.0 }
      end

      def storage_out
        residual_demand.map { |v| v.negative? ? -v : 0.0 }
      end

      def storage_volume
        cumulative = cumulative_residual_demand

        volume = []

        residual_demand.each.with_index do |value, index|
          previous = index.zero? ? cumulative.min.abs : volume[index - 1]

          volume[index] = previous + value
        end

        volume
      end
    end
  end
end
