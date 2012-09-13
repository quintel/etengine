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
    # This belongs mostly to the presentation layer, so this method could be
    # moved somewhere else, but it needs access to the graph method to get the
    # list of carriers.
    # The extra hash can be used to pass extra parameters as needed.
    #
    def calculation_methods
      out = {
        :demand => {
          :demand                        => {},
          :preset_demand                 => {},
          :demand_of_sustainable         => {},
          :weighted_carrier_cost_per_mj  => {},
          :weighted_carrier_co2_per_mj   => {},
          :sustainability_share          => {},
          :final_demand                  => {},
          :primary_demand                => {},
          :primary_demand_of_fossil      => {},
          :primary_demand_of_sustainable => {}
        },
        :new => {
          :nominal_input_capacity => {},
          :effective_input_capacity => {},
          :total_costs => {},
          :fixed_costs => {},
          :cost_of_capital => {},
          :depreciation_costs => {},
          :variable_costs => {},
          :fuel_costs => {},
          :number_of_units => {},
          :co2_emissions_costs => {},
          :variable_operation_and_maintenance_costs => {},
          :initial_investment_costs => {},
          :typical_fuel_input => {}
        },
        :old => {
          :mw_input_capacity => {},
          :typical_input_capacity => {}
        }
      }
      graph.carriers.each do |c|
        method_name = "primary_demand_of_#{c.key}".to_sym
        out[:demand][method_name] = {hide_if_zero: true}
      end
      out
    end
  end
end
