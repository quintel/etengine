module Qernel
  class ConverterApi
    # Used by the data/converter/show page
    SHARED_ATTRIBUTES = {
      :technical => {
          :average_effective_output_of_nominal_capacity_over_lifetime => ['Average effective output of nominal capacity over lifetime', '%'],
          :full_load_hours  => ['Full load hours', 'hour / year'],
        },
      :cost => {
          :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs', 'euro / full load hour'],
          :part_ets  => ['Do emissions have to be paid for through the ETS?', 'yes=1 / no=0'],
          :wacc  => ['Weighted average cost of capital', '%']
        },
      :other => {
        :land_use_per_unit  => ['Land use per unit', 'km2'],
        :technical_lifetime  => ['Technical lifetime', 'year']
      }
    }

    ELECTRICITY_PRODUCTION_VALUES  = SHARED_ATTRIBUTES.deep_merge({
      :technical => {
        :nominal_capacity_electricity_output_per_unit => ['Nominal electrical capacity','MW'],
        :electricity_output_conversion  => ['Electrical efficiency', '%'],
        :heat_output_conversion  => ['Heat efficiency', '%']
      },
      :cost => {
        :initial_investment_excl_ccs_per_mwe => ['Initial investment (excl CCS)', 'euro / MWe'],
        :additional_investment_ccs_per_mwe => ['Additional inititial investment for CCS', 'euro / MWe'],
        :decommissioning_costs_per_mwe => ['Decommissioning costs','euro / MWe'],
        :fixed_yearly_operation_and_maintenance_costs_per_mwe => ['Fixed operation and maintenance costs','euro / MWe / year'],
        :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs (excl CCS)', 'euro / full load hour'],
        :ccs_operation_and_maintenance_cost_per_full_load_hour  => ['Additional variable operation and maintenance costs for CCS', 'euro / full load hour']
      },
      :other => {
        :construction_time  => ['Construction time', 'year']
      }
    })

    HEAT_PRODUCTION_VALUES  = SHARED_ATTRIBUTES.deep_merge({
      :technical => {
        :nominal_capacity_heat_output_per_unit => ['Nominal heat capacity','MW'],
        :heat_output_conversion  => ['Heat efficiency', '%']
      },
      :cost => {
        :purchase_price_per_unit => ['Initial purchase price', 'euro'],
        :installing_costs_per_unit => ['Cost of installing','euro'],
        :residual_value_per_unit => ['Residual value after lifetime','euro'],
        :decommissioning_costs_per_unit => ['Decommissioning costs','euro'],
        :fixed_yearly_operation_and_maintenance_costs_per_unit => ['Fixed operation and maintenance costs','euro / year']
      }
    })

    HEAT_PUMP_VALUES  =  SHARED_ATTRIBUTES.deep_merge({
      :technical => {
        :nominal_capacity_heat_output_per_unit => ['Nominal heat capacity','MW'],
        :coefficient_of_performance => ['Coefficient of Performance', ''],
        :heat_and_cold_output_conversion  => ['Efficiency (after COP)', '%']
      },
      :cost => {
        :purchase_price_per_unit => ['Initial purchase price', 'euro'],
        :installing_costs_per_unit => ['Cost of installing','euro'],
        :residual_value_per_unit => ['Residual value after lifetime','euro'],
        :decommissioning_costs_per_unit => ['Decommissioning costs','euro'],
        :fixed_yearly_operation_and_maintenance_costs_per_unit => ['Fixed operation and maintenance costs','euro / year']
      }
    })

    CHP_VALUES  = SHARED_ATTRIBUTES.deep_merge({
      :technical => {
        :nominal_capacity_electricity_output_per_unit => ['Nominal electrical capacity','MW'],
        :nominal_capacity_heat_output_per_unit => ['Nominal heat capacity','MW'],
        :electricity_output_conversion  => ['Electrical efficiency', '%'],
        :heat_output_conversion  => ['Heat efficiency', '%']
      },
      :cost => {
        :initial_investment_excl_ccs_per_unit => ['Initial investment (excl CCS)', 'euro'],
        :additional_investment_ccs_per_unit => ['Additional inititial investment for CCS', 'euro'],
        :decommissioning_costs_per_unit => ['Decommissioning costs','euro'],
        :fixed_yearly_operation_and_maintenance_costs_per_unit => ['Fixed operation and maintenance costs','euro / year'],
        :operation_and_maintenance_cost_variable_per_full_load_hour  => ['Variable operation and maintenance costs (excl CCS)', 'euro / full load hour'],
        :ccs_operation_and_maintenance_cost_per_full_load_hour  => ['Additional variable operation and maintenance costs for CCS', 'euro / full load hour']
      },
      :other => {
        :construction_time  => ['Construction time', 'year']
      }
    })

    # some converters use extra attributes. Rather than messing up the views I
    # add the method here. I hope this will be removed
    def uses_coal_and_wood_pellets?
      carriers = converter.input_carriers.map &:key
      carriers.include?(:coal) && carriers.include?(:wood_pellets)
    end

    # combines the *_VALUES hashes as needed. This is used in the converter
    # details page, in the /data section and through the API (v3)
    def relevant_attributes
      out = {}
      out = out.deep_merge HEAT_PRODUCTION_VALUES if
        converter.groups.include?(:cost_traditional_heat)
      out = out.deep_merge ELECTRICITY_PRODUCTION_VALUES if
        converter.groups.include?(:cost_electricity_production)
      out = out.deep_merge HEAT_PUMP_VALUES if
        converter.groups.include?(:cost_heat_pumps)
      out = out.deep_merge CHP_VALUES if
        converter.groups.include?(:cost_chps)

      # custom stuff, trying to keep the view simple
      if uses_coal_and_wood_pellets?
        out[:current_fuel_input_mix] = {}
        fuel_mix = {}
        converter.input_links.each do |link|
          fuel_mix["#{link.carrier.key}_input_conversion"] = [link.carrier.key.to_s.humanize, '%']
        end
        out[:current_fuel_input_mix] = fuel_mix
      end
      out
    end
  end
end