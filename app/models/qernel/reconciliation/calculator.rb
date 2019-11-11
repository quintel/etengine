module Qernel
  module Reconciliation
    class Calculator
      def initialize(demand, supply)
        @total_demand = demand
        @total_supply = supply
      end

      def inspect
        "#<#{self.class} " \
          "demand=#{@total_demand.sum} " \
          "supply=#{@total_supply.sum}>"
      end

      # Public: Takes the total demand and supply curves, calculating for each
      # hour the difference between demand and supply.
      #
      # Positive values indicate a surplus, while negative values are deficits.
      #
      # Returns an array.
      def surplus
        result = Array.new(@total_demand.length)

        # Hold the current index and increment in each iteration: its faster to
        # do this - and prealloate the result array - than to create an empty
        # array and push each result.
        index = -1

        @total_demand.zip(@total_supply) do |demand, supply|
          sum = -demand + supply
          result[index += 1] = sum.abs < 1e-5 ? 0.0 : sum
        end

        result
      end

      # Public: Takes the hourly surplus curve, and calculates for each hour
      # the total amount of surplus energy up to that point in the year.
      #
      # Positive values represent a surplus, while negative values are deficits.
      #
      # Returns an array.
      def cumulative_surplus
        curve = surplus
        cumulative = []

        curve.each.with_index do |value, index|
          cumulative.push(index.zero? ? value : value + cumulative[index - 1])
        end

        cumulative
      end

      def storage_in
        surplus.map { |v| v.positive? ? v : 0.0 }
      end

      def storage_out
        surplus.map { |v| v.negative? ? -v : 0.0 }
      end

      # Public: Computes the energy which must be stored in the global buffer
      # for each hour of the year in order to balance supply and demand.
      #
      # Returns a curve.
      def storage_volume
        chs = cumulative_surplus
        chs_min = chs.min

        chs.map { |val| val - chs_min }
      end

      private

      # Internal: Iterates through the value pairs of each array, creating a new
      # array by executing the block on each pair.
      #
      # Returns an array.
      def zip_map(left, right)
        result = Array.new(left.length)

        # Hold the current index and increment in each iteration: its faster to
        # do this and prealloate the result array, than to create an empty array
        # and push each result.
        index = -1

        left.zip(right) do |l_val, r_val|
          result[index += 1] = yield(l_val, r_val)
        end

        result
      end
    end
  end
end
