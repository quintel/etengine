module Qernel
  class ConverterApi
    # All the static attributes that come from the database
    # Access the following attributes with @. e.g
    #   @demand_expected_value *and not* demand_expected_value (or self.demand_expected_value)
    ATTRIBUTE_GROUPS = {
      :operational => {
        :average_effective_output_of_nominal_capacity_over_lifetime => ['desc', 'unit'],
        :co2_free => ['desc', 'unit'],
        :construction_time => ['desc', 'unit'],
        :electrical_efficiency_when_using_coal => ['desc', 'unit'],
        :electrical_efficiency_when_using_wood_pellets => ['desc', 'unit'],
        :full_load_hours => ['desc', 'unit'],
        :households_supplied_per_unit => ['desc', 'unit'],
        :land_use_per_unit => ['desc', 'unit'],
        :part_ets => ['desc', 'unit'],
        :peak_load_units => ['desc', 'unit'],
        :peak_load_units_present => ['desc', 'unit'],
        :technical_lifetime => ['desc', 'unit'],
        :typical_nominal_input_capacity => ['desc', 'unit']
      },

      :cost => {
        :lifetime => ['just a test', 'years'],
        :total_real_costs => ['just a test here', 'euros'],

        :ccs_investment_per_mw_input => ['desc', 'unit'],
        :ccs_operation_and_maintenance_cost_per_full_load_hour => ['desc', 'unit'],
        :costs_per_mj => ['desc', 'unit'],
        :decommissioning_costs_per_mw_input => ['desc', 'unit'],
        :installing_costs_per_mw_input => ['desc', 'unit'],
        :operation_and_maintenance_cost_fixed_per_mw_input => ['desc', 'unit'],
        :operation_and_maintenance_cost_variable_per_full_load_hour => ['desc', 'unit'],
        :purchase_price_per_mw_input => ['desc', 'unit'],
        :residual_value_per_mw_input => ['desc', 'unit'],
        :wacc => ['desc', 'unit']
      },

      :network => {
        :network_capacity_available_in_mw => ['desc', 'unit'],
        :network_capacity_used_in_mw => ['desc', 'unit'],
        :network_expansion_costs_in_euro_per_mw => ['desc', 'unit'],
        :simult_sd => ['desc', 'unit'],
        :simult_se => ['desc', 'unit'],
        :simult_wd => ['desc', 'unit'],
        :simult_we => ['desc', 'unit'],
        :simult_supply => ['desc', 'unit']
      },

      :merit_order => {
        :merit_order_start => ['desc', 'unit'],
        :merit_order_end => ['desc', 'unit'],
        :merit_order_full_load_hours => ['desc', 'unit'],
        :merit_order_capacity_factor => ['desc', 'unit'],
        :merit_order_position => ['desc', 'unit']
      },

      :security_of_supply => {
        :availability => ['desc', 'unit'],
        :variability => ['desc', 'unit'],
        :part_load_operating_point => ['desc', 'unit'],
        :part_load_efficiency_penalty => ['desc', 'unit'],
        :forecasting_error => ['desc', 'unit']
      },

      :misc => {
        :demand_expected_value => ['desc', 'unit'],
        :excel_id => ['desc', 'unit'], # temporary fix to still support excel_ids. used now for graphviz
        :max_demand => ['desc', 'unit'] # I would like to see this attribute in Converter, as it influences calculation
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
