module Qernel
  class ConverterApi
    # All the static attributes that come from the database
    # Access the following attributes with @. e.g
    #   @demand_expected_value *and not* demand_expected_value (or self.demand_expected_value)
    ATTRIBUTE_GROUPS = {
      :operational => {
        :average_effective_output_of_nominal_capacity_over_lifetime => ['Average effective output of nominal capacity over lifetime', '%'],
        :co2_free => ['', ''],
        :construction_time => ['Construction time', 'year'],
        :electrical_efficiency_when_using_coal => ['', ''],
        :electrical_efficiency_when_using_wood_pellets => ['', ''],
        :full_load_hours => ['Full load hours', 'hour / year'],
        :households_supplied_per_unit => ['', ''],
        :land_use_per_unit => ['Land use per unit', 'km2'],
        :part_ets => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0'],
        :peak_load_units => ['', ''],
        :peak_load_units_present => ['', ''],
        :technical_lifetime => ['Technical lifetime', 'year'],
        :typical_nominal_input_capacity => ['', '']
      },

      :cost => {
        :ccs_investment_per_mw_input => ['', ''],
        :ccs_operation_and_maintenance_cost_per_full_load_hour => ['Additional variable operation and maintenance costs for CCS', 'euro / full load hour'],
        :costs_per_mj => ['', ''],
        :decommissioning_costs_per_mw_input => ['', ''],
        :installing_costs_per_mw_input => ['', ''],
        :operation_and_maintenance_cost_fixed_per_mw_input => ['', ''],
        :operation_and_maintenance_cost_variable_per_full_load_hour => ['', 'euro / full load hour'],
        :purchase_price_per_mw_input => ['', ''],
        :residual_value_per_mw_input => ['', ''],
        :wacc => ['Weighted average cost of capital', '%']
      },

      :network => {
        :network_capacity_available_in_mw => ['', ''],
        :network_capacity_used_in_mw => ['', ''],
        :network_expansion_costs_in_euro_per_mw => ['', ''],
        :simult_sd => ['', ''],
        :simult_se => ['', ''],
        :simult_wd => ['', ''],
        :simult_we => ['', ''],
        :simult_supply => ['', '']
      },

      :merit_order => {
        :merit_order_start => ['', ''],
        :merit_order_end => ['', ''],
        :merit_order_full_load_hours => ['', ''],
        :merit_order_capacity_factor => ['', ''],
        :merit_order_position => ['', '']
      },

      :security_of_supply => {
        :availability => ['', ''],
        :variability => ['', ''],
        :part_load_operating_point => ['', ''],
        :part_load_efficiency_penalty => ['', ''],
        :forecasting_error => ['', '']
      },

      :misc => {
        :demand_expected_value => ['', ''],
        :excel_id => ['', ''], # temporary fix to still support excel_ids. used now for graphviz
        :max_demand => ['', ''] # I would like to see this attribute in Converter, as it influences calculation
      }
    }

    ATTRIBUTES_USED = ATTRIBUTE_GROUPS.values.map(&:keys).flatten

    # For the data/converter/show page we need grouping of the attributes. These
    # attribute groups should only be used to show the values in the data section
    ELECTRICITY_PRODUCTION_VALUES  =  {
      :technical => {
        :nominal_capacity_electricity_output_per_unit => ['Nominal electrical capacity','MW'],
        :average_effective_output_of_nominal_capacity_over_lifetime => ['Average effective output of nominal capacity over lifetime', '%'],
        :full_load_hours  => ['Full load hours', 'hour / year'],
        :electricity_output_conversion  => ['Electrical efficiency', '%'],
        :heat_output_conversion  => ['Heat efficiency', '%']
      },
      :cost => {
        :initial_investment_excl_ccs_per_mwe => ['Initial investment (excl CCS)', 'euro / MWe'],
        :additional_investment_ccs_per_mwe => ['Additional inititial investment for CCS', 'euro / MWe'],
        :decommissioning_costs_per_mwe => ['Decommissioning costs','euro / MWe'],
        :fixed_yearly_operation_and_maintenance_costs_per_mwe => ['Fixed operation and maintenance costs','euro / MWe / year'],
        :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs (excl CCS)', 'euro / full load hour'],
        :ccs_operation_and_maintenance_cost_per_full_load_hour  => ['Additional variable operation and maintenance costs for CCS', 'euro / full load hour'],
        :wacc  => ['Weighted average cost of capital', '%'],
        :part_ets  => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0']
      },
      :other => {
        :land_use_per_unit  => ['Land use per unit', 'km2'],
        :construction_time  => ['Construction time', 'year'],
        :technical_lifetime  => ['Technical lifetime', 'year']
      }
    }

    HEAT_PRODUCTION_VALUES  =  {
      :technical => {
        :nominal_capacity_heat_output_per_unit => ['Nominal heat capacity','MW'],
        :average_effective_output_of_nominal_capacity_over_lifetime => ['Average effective output of nominal capacity over lifetime', '%'],
        :full_load_hours  => ['Full load hours', 'hour / year'],
        :heat_output_conversion  => ['Heat efficiency', '%']
      },
      :cost => {
        :purchase_price_per_unit => ['Initial purchase price', 'euro'],
        :installing_costs_per_unit => ['Cost of installing','euro'],
        :residual_value_per_unit => ['Residual value after lifetime','euro'],
        :decommissioning_costs_per_unit => ['Decommissioning costs','euro'],
        :fixed_yearly_operation_and_maintenance_costs_per_unit => ['Fixed operation and maintenance costs','euro / year'],
        :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs', 'euro / full load hour'],
        :wacc  => ['Weighted average cost of capital', '%'],
        :part_ets  => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0']
      },
      :other => {
        :land_use_per_unit  => ['Land use per unit', 'km2'],
        :technical_lifetime  => ['Technical lifetime', 'year']
      }
    }

    HEAT_PUMP_VALUES  =  {
      :technical => {
        :nominal_capacity_heat_output_per_unit => ['Nominal heat capacity','MW'],
        :average_effective_output_of_nominal_capacity_over_lifetime => ['Average effective output of nominal capacity over lifetime', '%'],
        :full_load_hours  => ['Full load hours', 'hour / year'],
        :coefficient_of_performance => ['Coefficient of Performance', ''],
        :heat_and_cold_output_conversion  => ['Efficiency (after COP)', '%']
      },
      :cost => {
        :purchase_price_per_unit => ['Initial purchase price', 'euro'],
        :installing_costs_per_unit => ['Cost of installing','euro'],
        :residual_value_per_unit => ['Residual value after lifetime','euro'],
        :decommissioning_costs_per_unit => ['Decommissioning costs','euro'],
        :fixed_yearly_operation_and_maintenance_costs_per_unit => ['Fixed operation and maintenance costs','euro / year'],
        :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs', 'euro / full load hour'],
        :wacc  => ['Weighted average cost of capital', '%'],
        :part_ets  => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0']
      },
      :other => {
        :land_use_per_unit  => ['Land use per unit', 'km2'],
        :technical_lifetime  => ['Technical lifetime', 'year']
      }
    }

    CHP_VALUES  =  {
      :technical => {
        :nominal_capacity_electricity_output_per_unit => ['Nominal electrical capacity','MW'],
        :nominal_capacity_heat_output_per_unit => ['Nominal heat capacity','MW'],
        :average_effective_output_of_nominal_capacity_over_lifetime => ['Average effective output of nominal capacity over lifetime', '%'],
        :full_load_hours  => ['Full load hours', 'hour / year'],
        :electricity_output_conversion  => ['Electrical efficiency', '%'],
        :heat_output_conversion  => ['Heat efficiency', '%']
      },
      :cost => {
        :initial_investment_excl_ccs_per_unit => ['Initial investment (excl CCS)', 'euro'],
        :additional_investment_ccs_per_unit => ['Additional inititial investment for CCS', 'euro'],
        :decommissioning_costs_per_unit => ['Decommissioning costs','euro'],
        :fixed_yearly_operation_and_maintenance_costs_per_unit => ['Fixed operation and maintenance costs','euro / year'],
        :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs (excl CCS)', 'euro / full load hour'],
        :ccs_operation_and_maintenance_cost_per_full_load_hour  => ['Additional variable operation and maintenance costs for CCS', 'euro / full load hour'],
        :wacc  => ['Weighted average cost of capital', '%'],
        :part_ets  => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0']
      },
      :other => {
        :land_use_per_unit  => ['Land use per unit', 'km2'],
        :construction_time  => ['Construction time', 'year'],
        :technical_lifetime  => ['Technical lifetime', 'year']
      }
    }
    dataset_accessors ATTRIBUTES_USED
  end
end