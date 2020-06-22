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


    # used now in api/v3/node.rb and data node detail page.
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
        :technical => {
          :input_capacity => {},
          :electric_based_input_capacity => {label: '', unit: 'MWinput'},
          :heat_based_input_capacity => {label: '', unit: 'MWinput'},
          :cooling_based_input_capacity => {label: '', unit: 'MWinput'},
          :number_of_units => {}
        },
        :costs_per_plant => {
          'total_costs_per(:plant)'                                  => {label: 'Total costs per plant', unit: 'euro / plant'},
          'fixed_costs_per(:plant)'                                  => {},
          'cost_of_capital_per(:plant)'                              => {},
          'depreciation_costs_per(:plant)'                           => {},
          'variable_costs_per(:plant)'                               => {},
          'fuel_costs_per(:plant)'                                   => {},
          'co2_emissions_costs_per(:plant)'                          => {},
          'fixed_operation_and_maintenance_costs_per(:plant)'        => {},
          'variable_operation_and_maintenance_costs_per(:plant)'     => {},
          'total_initial_investment_per(:plant)'                     => {},
        },
        :costs_per_node => {
          'total_costs_per(:node)'                              => {},
          'fixed_costs_per(:node)'                              => {},
          'cost_of_capital_per(:node)'                          => {},
          'depreciation_costs_per(:node)'                       => {},
          'variable_costs_per(:node)'                           => {},
          'fuel_costs_per(:node)'                               => {},
          'co2_emissions_costs_per(:node)'                      => {},
          'fixed_operation_and_maintenance_costs_per(:node)'    => {},
          'variable_operation_and_maintenance_costs_per(:node)' => {},
          'total_initial_investment_per(:node)'                 => {},
        },
        :costs_per_mw_electricity => {
          'total_costs_per(:mw_electricity)'                              => {},
          'fixed_costs_per(:mw_electricity)'                              => {},
          'cost_of_capital_per(:mw_electricity)'                          => {},
          'depreciation_costs_per(:mw_electricity)'                       => {},
          'variable_costs_per(:mw_electricity)'                           => {},
          'fuel_costs_per(:mw_electricity)'                               => {},
          'co2_emissions_costs_per(:mw_electricity)'                      => {},
          'fixed_operation_and_maintenance_costs_per(:mw_electricity)'    => {},
          'variable_operation_and_maintenance_costs_per(:mw_electricity)' => {},
          'total_initial_investment_per(:mw_electricity)'                 => {},
        },
        :costs_per_mwh_electricity => {
          'total_costs_per(:mwh_electricity)'                              => {},
          'fixed_costs_per(:mwh_electricity)'                              => {},
          'cost_of_capital_per(:mwh_electricity)'                          => {},
          'depreciation_costs_per(:mwh_electricity)'                       => {},
          'variable_costs_per(:mwh_electricity)'                           => {},
          'fuel_costs_per(:mwh_electricity)'                               => {},
          'co2_emissions_costs_per(:mwh_electricity)'                      => {},
          'fixed_operation_and_maintenance_costs_per(:mwh_electricity)'    => {},
          'variable_operation_and_maintenance_costs_per(:mwh_electricity)' => {},
          'total_initial_investment_per(:mwh_electricity)'                 => {},
        },
        :costs_per_mw_heat => {
          'total_costs_per(:mw_heat)'                              => {},
          'fixed_costs_per(:mw_heat)'                              => {},
          'cost_of_capital_per(:mw_heat)'                          => {},
          'depreciation_costs_per(:mw_heat)'                       => {},
          'variable_costs_per(:mw_heat)'                           => {},
          'fuel_costs_per(:mw_heat)'                               => {},
          'co2_emissions_costs_per(:mw_heat)'                      => {},
          'fixed_operation_and_maintenance_costs_per(:mw_heat)'    => {},
          'variable_operation_and_maintenance_costs_per(:mw_heat)' => {},
          'total_initial_investment_per(:mw_heat)'                 => {},
        },
        :costs_per_mwh_heat => {
          'total_costs_per(:mwh_heat)'                              => {},
          'fixed_costs_per(:mwh_heat)'                              => {},
          'cost_of_capital_per(:mwh_heat)'                          => {},
          'depreciation_costs_per(:mwh_heat)'                       => {},
          'variable_costs_per(:mwh_heat)'                           => {},
          'fuel_costs_per(:mwh_heat)'                               => {},
          'co2_emissions_costs_per(:mwh_heat)'                      => {},
          'fixed_operation_and_maintenance_costs_per(:mwh_heat)'    => {},
          'variable_operation_and_maintenance_costs_per(:mwh_heat)' => {},
          'total_initial_investment_per(:mwh_heat)'                 => {},
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
