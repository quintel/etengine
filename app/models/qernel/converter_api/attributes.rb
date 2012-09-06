module Qernel
  class ConverterApi
    # All the static attributes that come from the database
    # Access the following attributes with @. e.g
    #   @demand_expected_value *and not* demand_expected_value (or self.demand_expected_value)
    #
    # DEBT: 'desc' seems to be unused. Use it!
    ATTRIBUTE_GROUPS = {
      :new => {
        :initial_investment => ['desc', 'euro / unit'],
        :ccs_investment => ['desc', 'euro / unit'],
        :cost_of_installing => ['desc', 'euro / unit'],
        :decommissioning_costs => ['desc', 'euro / unit'],
        :residual_value => ['desc', 'euro / unit'],
        :fixed_operation_and_maintenance_costs_per_year => ['desc', 'euro / unit / year'],
        :variable_operation_and_maintenance_costs_per_full_load_hour => ['desc', 'euro / full load hour'],
        :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour => ['desc', 'euro / full load hour'],
        :electricity_output_capacity => ['desc', 'MWe'],
        :heat_output_capacity => ['desc', 'MWth'],
        :electric_based_nominal_input_capacity => ['desc', 'MWe']
      },

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
        :typical_nominal_input_capacity => ['desc', 'unit'] # Deprecated by new cost calculation
      },

      :cost => {
        :ccs_investment_per_mw_input => ['desc', 'unit'], # Deprecated by new cost calculation
        :ccs_operation_and_maintenance_cost_per_full_load_hour => ['desc', 'unit'], # Deprecated by new cost calculation
        :costs_per_mj => ['desc', 'unit'],
        :decommissioning_costs_per_mw_input => ['desc', 'unit'], # Deprecated by new cost calculation
        :installing_costs_per_mw_input => ['desc', 'unit'], # Deprecated by new cost calculation
        :operation_and_maintenance_cost_fixed_per_mw_input => ['desc', 'unit'], # Deprecated by new cost calculation
        :operation_and_maintenance_cost_variable_per_full_load_hour => ['desc', 'unit'], # Deprecated by new cost calculation
        :purchase_price_per_mw_input => ['desc', 'unit'], # Deprecated by new cost calculation
        :residual_value_per_mw_input => ['desc', 'unit'], # Deprecated by new cost calculation
        :wacc => ['desc', 'unit']
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

    dataset_accessors ATTRIBUTES_USED
  end
end
