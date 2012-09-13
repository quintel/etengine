module Qernel
  class ConverterApi
    # All the static attributes that come from the database
    # Access the following attributes with @. e.g
    #   @demand_expected_value *and not* demand_expected_value (or self.demand_expected_value)
    #
    # DEBT: 'desc' seems to be unused. Use it!
    #
    # PZ: in the converter detail page only a subset of these attributes is
    # shown. They are defined in a new file, group_specific_attributes.rb.
    ATTRIBUTE_GROUPS = {
      :operational => {
        :electricity_output_capacity => ['', 'MWe'],
        :heat_output_capacity => ['', 'MWth'],
        :average_effective_output_of_nominal_capacity_over_lifetime => ['Average effective output of nominal capacity over lifetime', '%'],
        :co2_free => ['', ''],
        :construction_time => ['', ''],
        :electrical_efficiency_when_using_coal => ['', ''],
        :electrical_efficiency_when_using_wood_pellets => ['', ''],
        :full_load_hours => ['', ''],
        :households_supplied_per_unit => ['', ''],
        :land_use_per_unit => ['', ''],
        :part_ets => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0'],
        :peak_load_units => ['', ''],
        :peak_load_units_present => ['', ''],
        :technical_lifetime => ['Technical lifetime', 'year'],
        :typical_nominal_input_capacity => ['', ''] # Deprecated by new cost calculation
      },

      :cost => {
        :initial_investment => ['', 'euro / unit'],
        :ccs_investment => ['', 'euro / unit'],
        :cost_of_installing => ['', 'euro / unit'],
        :decommissioning_costs => ['', 'euro / unit'],
        :residual_value => ['', 'euro / unit'],
        :fixed_operation_and_maintenance_costs_per_year => ['', 'euro / unit / year'],
        :variable_operation_and_maintenance_costs_per_full_load_hour => ['', 'euro / full load hour'],
        :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour => ['', 'euro / full load hour'],
        :ccs_investment_per_mw_input => ['', ''], # Deprecated by new cost calculation
        :ccs_operation_and_maintenance_cost_per_full_load_hour => ['', ''], # Deprecated by new cost calculation
        :costs_per_mj => ['', ''],
        :decommissioning_costs_per_mw_input => ['', ''], # Deprecated by new cost calculation
        :installing_costs_per_mw_input => ['', ''], # Deprecated by new cost calculation
        :operation_and_maintenance_cost_fixed_per_mw_input => ['', ''], # Deprecated by new cost calculation
        :operation_and_maintenance_cost_variable_per_full_load_hour => ['', ''], # Deprecated by new cost calculation
        :purchase_price_per_mw_input => ['', ''], # Deprecated by new cost calculation
        :residual_value_per_mw_input => ['', ''], # Deprecated by new cost calculation
        :wacc => ['', '']
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
