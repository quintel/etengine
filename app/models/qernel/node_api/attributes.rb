module Qernel
  module NodeApi
    module Attributes
      # All the static attributes that come from the database
      # Access the following attributes with @. e.g
      #   @demand_expected_value *and not* demand_expected_value (or self.demand_expected_value)
      #
      # DEBT: 'desc' seems to be unused. Use it!
      #
      # PZ: in the node detail page only a subset of these attributes is
      # shown. They are defined in a new file, group_specific_attributes.rb.
      ATTRIBUTE_GROUPS = {
        :operational => {
          :electricity_output_capacity => ['', 'MWe'],
          :heat_output_capacity => ['', 'MWth'],
          :hydrogen_output_capacity => ['', 'MW'],
          :free_co2_factor => ['', ''],
          :ccs_capture_rate => ['', ''],
          :construction_time => ['', ''],
          :electrical_efficiency_when_using_coal => ['', ''],
          :electrical_efficiency_when_using_wood_pellets => ['', ''],
          :full_load_hours => ['', ''],
          :households_supplied_per_unit => ['', ''],
          :land_use_per_unit => ['', ''],
          :takes_part_in_ets => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0'],
          :technical_lifetime => ['Technical lifetime', 'year'],
          :typical_input_capacity => ['', 'MWinput'],
          :output_capacity => ['', 'MW'],
          :input_efficiency => ['', ''],
          :output_efficiency => ['', '']
        },

        :cost => {
          :initial_investment => ['', 'euro / unit'],
          :ccs_investment => ['', 'euro / unit'],
          :cost_of_installing => ['', 'euro / unit'],
          :decommissioning_costs => ['', 'euro / unit'],
          :fixed_operation_and_maintenance_costs_per_year => ['', 'euro / unit / year'],
          :variable_operation_and_maintenance_costs_per_full_load_hour => ['', 'euro / full load hour'],
          :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour => ['', 'euro / full load hour'],
          :fixed_costs_per_mw_input_capacity => ['', 'euro / MWinput'],
          :costs_per_mj => ['', ''],
          :wacc => ['', ''],
          :profitability => ['', 'profitable / unprofitable / conditionally_profitable'], # Used by merit order
          :profit_per_mwh_electricity => ['', 'eur/MWh'],  # Used by merit order,
          :marginal_costs => ['', 'euro / MWh'],
          :max_consumption_price => ['', 'euro / MWh'],
          :capital_expenditures => ['', 'euro / unit / year'],
          :operating_expenses => ['', 'euro / unit / year'],
          :operating_expenses_including_fuel => ['', 'euro / unit / year'],
          :revenue => ['', 'euro / unit / year']
        },

        :merit_order => {
          :merit_order_full_load_hours => ['', ''],
          :merit_order_capacity_factor => ['', ''],
          :merit_order_position => ['', '']
        },

        :security_of_supply => {
          :availability => ['', ''],
          :part_load_operating_point => ['', ''],
          :part_load_efficiency_penalty => ['', ''],
          :forecasting_error => ['', '']
        },

        :misc => {
          :demand_expected_value => ['', ''],
          :excel_id => ['', ''], # temporary fix to still support excel_ids. used now for graphviz
          :max_demand => ['', ''] # I would like to see this attribute in Node, as it influences calculation
        }
      }

      ATTRIBUTES_USED = ATTRIBUTE_GROUPS.values.map(&:keys).flatten
    end
  end
end
