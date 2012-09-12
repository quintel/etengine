module Qernel
  module MethodMetaData

    # Sums all non-nil values.
    # Returns nil if all values are nil.
    #
    # @param [Array<Float,nil>] Values to sum
    # @return [Float,nil] The sum of all values. nil if all values are nil
    #
    def sum_unless_empty(values)
      values = values.compact
      values.empty? ? nil : values.sum
    end


    # used now in api/v3/converter.rb and data converter detail page.
    # Returns a hash with the methods (grouped by category) to be shown
    #
    def calculation_methods
      out = {
        :demand => [
          :demand,
          :preset_demand,
          :demand_of_sustainable,
          :weighted_carrier_cost_per_mj,
          :weighted_carrier_co2_per_mj,
          :sustainability_share,
          :final_demand,
          :primary_demand,
          :primary_demand_of_fossil,
        :primary_demand_of_sustainable]
      }
      graph.carriers.each do |c|
        out[:demand] << "primary_demand_of_#{c.key}".to_sym
      end
      out
    end
  end
end
