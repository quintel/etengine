module Api
  module V3
    # This module defines which attributes and methods should be shown in the
    # converter detail popup. The API converter detail requests shows this stuff
    #
    module ConverterPresenterData
      # If the converter belongs to the :cost_electricity_production group then
      # add these
      ELECTRICITY_PRODUCTION_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :electricity_output_capacity =>
            {label: 'Nominal electrical capacity', unit:'MW'},
          :average_effective_output_of_nominal_capacity_over_lifetime =>
            {label: 'Average effective output of nominal capacity over lifetime', unit: '%'},
          :electricity_output_conversion  =>
            {label: 'Electrical efficiency', unit: '%'},
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          :heat_output_conversion  =>
            {label: 'Heat efficiency', unit: '%'}
        },
        :cost => {
          'initial_investment_per(:mw_electricity)' =>
            {label: 'Initial investment (excl CCS)', unit: 'euro / MWe'},
          'ccs_investment_per(:mw_electricity)' =>
            {label: 'Additional inititial investment for CCS', unit: 'euro / MWe'},
          'decommissioning_costs_per(:mw_electricity)' =>
            {label: 'Decommissioning costs', unit:'euro / MWe'},
          'fixed_operation_and_maintenance_costs_per(:mw_electricity)' =>
            {label: 'Fixed operation and maintenance costs', unit:'euro / MWe / year'},
          :variable_operation_and_maintenance_costs_per_full_load_hour  =>
            {label: 'Variable operation and maintenance costs (excl CCS)', unit: 'euro / full load hour'},
          :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour  =>
            {label: 'Additional variable operation and maintenance costs for CCS', unit: 'euro / full load hour'},
          :wacc  =>
            {label: 'Weighted average cost of capital', unit: '%'},
          :part_ets  =>
            {label: 'Do emissions have to be paid for through the ETS?', unit: 'yes / no', formatter: lambda{|x| x == 1 ? 'yes' : 'no'}}
        },
        :other => {
          :land_use_per_unit  =>
            {label: 'Land use per unit', unit: 'km2'},
          :construction_time  =>
            {label: 'Construction time', unit: 'year'},
          :technical_lifetime  =>
            {label: 'Technical lifetime', unit: 'year'}
        }
      }

      # If the converter belongs to the :cost_traditional_heat group then
      # add these
      HEAT_PRODUCTION_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :heat_output_capacity =>
            {label: 'Nominal heat capacity', unit:'MW'},
          :average_effective_output_of_nominal_capacity_over_lifetime =>
            {label: 'Average effective output of nominal capacity over lifetime', unit: '%'},
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          :heat_output_conversion  =>
            {label: 'Heat efficiency', unit: '%'}
        },
        :cost => {
          'initial_investment_per(:plant)' =>
            {label: 'Initial purchase price', unit: 'euro'},
          'cost_of_installing_per(:plant)' =>
            {label: 'Cost of installing', unit:'euro'},
          'residual_value_per(:plant)' =>
            {label: 'Residual value after lifetime', unit:'euro'},
          'decommissioning_costs_per(:plant)' =>
            {label: 'Decommissioning costs', unit:'euro'},
          'fixed_operation_and_maintenance_costs_per(:plant)' =>
            {label: 'Fixed operation and maintenance costs', unit:'euro / year'},
          'variable_operation_and_maintenance_costs_per(:full_load_hour)'  =>
            {label: 'Variable operation and maintenance costs', unit: 'euro / full load hour'},
          :wacc  =>
            {label: 'Weighted average cost of capital', unit: '%'},
          :part_ets  =>
            {label: 'Do emissions have to be paid for through the ETS?', unit: 'yes / no', formatter: lambda{|x| x == 1 ? 'yes' : 'no'}}
        },
        :other => {
          :land_use_per_unit  =>
            {label: 'Land use per unit', unit: 'km2'},
          :technical_lifetime  =>
            {label: 'Technical lifetime', unit: 'year'}
        }
      }

      # If the converter belongs to the :cost_heat_pumps group then
      # add these
      HEAT_PUMP_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :heat_output_capacity =>
            {label: 'Nominal heat capacity', unit:'MW'},
          :average_effective_output_of_nominal_capacity_over_lifetime =>
            {label: 'Average effective output of nominal capacity over lifetime', unit: '%'},
          :coefficient_of_performance =>
            {label: 'Coefficient of Performance',  unit:''},
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          :heat_and_cold_output_conversion  =>
            {label: 'Efficiency (after COP)', unit: '%'}
        },
        :cost => {
          'initial_investment_per(:plant)' =>
            {label: 'Initial purchase price', unit: 'euro'},
          'cost_of_installing_per(:plant)' =>
            {label: 'Cost of installing', unit:'euro'},
          'residual_value_per(:plant)' =>
            {label: 'Residual value after lifetime', unit:'euro'},
          'decommissioning_costs_per(:plant)' =>
            {label: 'Decommissioning costs', unit:'euro'},
          'fixed_operation_and_maintenance_costs_per(:plant)' =>
            {label: 'Fixed operation and maintenance costs', unit:'euro / year'},
          'variable_operation_and_maintenance_costs_per(:full_load_hour)'  =>
            {label: 'Variable operation and maintenance costs', unit: 'euro / full load hour'},
          :wacc  =>
            {label: 'Weighted average cost of capital', unit: '%'},
          :part_ets  =>
            {label: 'Do emissions have to be paid for through the ETS?', unit: 'yes / no', formatter: lambda{|x| x == 1 ? 'yes' : 'no'}}
        },
        :other => {
          :land_use_per_unit  =>
            {label: 'Land use per unit', unit: 'km2'},
          :technical_lifetime  =>
            {label: 'Technical lifetime', unit: 'year'}
        }
      }

      # If the converter belongs to the :cost_chps group then
      # add these
      CHP_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :electricity_output_capacity =>
            {label: 'Nominal electrical capacity', unit: 'MW'},
          :average_effective_output_of_nominal_capacity_over_lifetime =>
            {label: 'Average effective output of nominal capacity over lifetime', unit: '%'},
          :heat_output_capacity =>
            {label: 'Nominal heat capacity', unit: 'MW'},
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          :electricity_output_conversion =>
            {label: 'Electrical efficiency', unit: '%'},
          :heat_output_conversion  =>
            {label: 'Heat efficiency',  unit: '%'}
        },
        :cost => {
          'initial_investment_per(:mw_electricity)' =>
            {label: 'Initial investment (excl CCS)', unit: 'euro / MWe'},
          'ccs_investment_per(:mw_electricity)' =>
            {label: 'Additional inititial investment for CCS', unit: 'euro / MWe'},
          'decommissioning_costs_per(:mw_electricity)' =>
            {label: 'Decommissioning costs', unit:'euro / MWe'},
          'fixed_operation_and_maintenance_costs_per(:mw_electricity)' =>
            {label: 'Fixed operation and maintenance costs', unit:'euro / MWe / year'},
          :variable_operation_and_maintenance_costs_per_full_load_hour  =>
            {label: 'Variable operation and maintenance costs (excl CCS)', unit: 'euro / full load hour'},
          :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour  =>
            {label: 'Additional variable operation and maintenance costs for CCS', unit: 'euro / full load hour'},
          :wacc  =>
            {label: 'Weighted average cost of capital', unit: '%'},
          :part_ets  =>
            {label: 'Do emissions have to be paid for through the ETS?', unit: 'yes / no', formatter: lambda{|x| x == 1 ? 'yes' : 'no'}}
        },
        :other => {
          :land_use_per_unit  =>
            {label: 'Land use per unit', unit: 'km2'},
          :construction_time =>
            {label: 'Construction time',  unit: 'year'},
          :technical_lifetime  =>
            {label: 'Technical lifetime', unit: 'year'}
        }
      }

      # some converters use extra attributes. Rather than messing up the views I
      # add the method here. I hope this will be removed
      def uses_coal_and_wood_pellets?
        carriers = @converter.input_carriers.map &:key
        carriers.include?(:coal) && carriers.include?(:wood_pellets)
      end

      # combines the *_VALUES hashes as needed. This is used in the converter
      # details page, in the /data section and through the API (v3)
      def attributes_and_methods_to_show
        out = HEAT_PRODUCTION_ATTRIBUTES_AND_METHODS        if @converter.groups.include?(:cost_traditional_heat)
        out = ELECTRICITY_PRODUCTION_ATTRIBUTES_AND_METHODS if @converter.groups.include?(:cost_electricity_production)
        out = HEAT_PUMP_ATTRIBUTES_AND_METHODS              if @converter.groups.include?(:cost_heat_pumps)
        out = CHP_ATTRIBUTES_AND_METHODS                    if @converter.groups.include?(:cost_chps)

        # custom stuff, trying to keep the view simple
        if uses_coal_and_wood_pellets?
          out[:current_fuel_input_mix] = {}
          fuel_mix = {}
          @converter.input_links.each do |link|
            fuel_mix["#{link.carrier.key}_input_conversion"] = {label: link.carrier.key.to_s.humanize, unit: '%'}
          end
          out[:current_fuel_input_mix] = fuel_mix
        end
        out
      end
    end
  end
end