module Qernel::Plugins
  module Hydrogen
    class Calculator
      def initialize(demand, supply)
        @total_demand = demand
        @total_supply = supply
      end

      def inspect
        "#<#{self.class} demand=#{@total_demand.sum} supply=#{@supply.sum}>"
      end

      # Public: Given a demand and supply curve, creates a new curve describing
      # the excess of demand (positive) or of supply (negative).
      def residual_demand
        result = Array.new(@total_demand.length)

        # Hold the current index and increment in each iteration: its faster to
        # do this and prealloate the result array, than to create an empty array
        # and push each result.
        index = -1

        @total_demand.zip(@total_supply) do |demand, supply|
          sum = -demand + supply
          result[index += 1] = sum.abs < 1e-5 ? 0.0 : sum
        end

        result
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
