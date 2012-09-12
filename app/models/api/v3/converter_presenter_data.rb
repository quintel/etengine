module Api
  module V3
    # This module defines which attributes and methods should be shown in the
    # converter detail popup. The API converter detail requests shows this stuff
    #
    module ConverterPresenterData
      # Converter attributes that are always showed
      #
      SHARED_ATTRIBUTES = {
        :technical => {
            :average_effective_output_of_nominal_capacity_over_lifetime =>
              {label: 'Average effective output of nominal capacity over lifetime', unit: '%'},
            :full_load_hours  =>
              {label: 'Full load hours', unit: 'hour / year'},
          },
        :cost => {
            :operation_and_maintenance_cost_variable_per_full_load_hour  =>
              {label: 'Variable operation and maintenance costs', unit: 'euro / full load hour'},
            :part_ets  =>
              {label: 'Do emissions have to be paid for through the ETS?', unit: 'yes=1 / no=0'},
            :wacc  =>
              {label: 'Weighted average cost of capital', unit: '%'}
          },
        :other => {
          :land_use_per_unit  =>
            {label: 'Land use per unit', unit: 'km2'},
          :technical_lifetime  =>
            {label: 'Technical lifetime', unit: 'year'}
        }
      }

      # If the converter belongs to the :cost_electricity_production group then
      # add these
      ELECTRICITY_PRODUCTION_VALUES  = SHARED_ATTRIBUTES.deep_merge({
        :technical => {
          :nominal_capacity_electricity_output_per_unit =>
            {label: 'Nominal electrical capacity', unit:'MW'},
          :electricity_output_conversion  =>
            {label: 'Electrical efficiency', unit: '%'},
          :heat_output_conversion  =>
            {label: 'Heat efficiency', unit: '%'}
        },
        :cost => {
          :initial_investment_excl_ccs_per_mwe =>
            {label: 'Initial investment (excl CCS)', unit: 'euro / MWe'},
          :additional_investment_ccs_per_mwe =>
            {label: 'Additional inititial investment for CCS', unit: 'euro / MWe'},
          :decommissioning_costs_per_mwe =>
            {label: 'Decommissioning costs', unit:'euro / MWe'},
          :fixed_yearly_operation_and_maintenance_costs_per_mwe =>
            {label: 'Fixed operation and maintenance costs', unit:'euro / MWe / year'},
          :operation_and_maintenance_cost_variable_per_full_load_hour  =>
            {label: 'Variable operation and maintenance costs (excl CCS)', unit: 'euro / full load hour'},
          :ccs_operation_and_maintenance_cost_per_full_load_hour  =>
            {label: 'Additional variable operation and maintenance costs for CCS', unit: 'euro / full load hour'}
        },
        :other => {
          :construction_time  =>
            {label: 'Construction time', unit: 'year'}
        }
      })

      # If the converter belongs to the :cost_traditional_heat group then
      # add these
      HEAT_PRODUCTION_VALUES  = SHARED_ATTRIBUTES.deep_merge({
        :technical => {
          :nominal_capacity_heat_output_per_unit =>
            {label: 'Nominal heat capacity', unit:'MW'},
          :heat_output_conversion  =>
            {label: 'Heat efficiency', unit: '%'}
        },
        :cost => {
          :purchase_price_per_unit =>
            {label: 'Initial purchase price', unit: 'euro'},
          :installing_costs_per_unit =>
            {label: 'Cost of installing', unit:'euro'},
          :residual_value_per_unit =>
            {label: 'Residual value after lifetime', unit:'euro'},
          :decommissioning_costs_per_unit =>
            {label: 'Decommissioning costs', unit:'euro'},
          :fixed_yearly_operation_and_maintenance_costs_per_unit =>
            {label: 'Fixed operation and maintenance costs', unit:'euro / year'}
        }
      })

      # If the converter belongs to the :cost_heat_pumps group then
      # add these
      HEAT_PUMP_VALUES  =  SHARED_ATTRIBUTES.deep_merge({
        :technical => {
          :nominal_capacity_heat_output_per_unit =>
            {label: 'Nominal heat capacity', unit:'MW'},
          :coefficient_of_performance =>
            {label: 'Coefficient of Performance',  unit:''},
          :heat_and_cold_output_conversion  =>
            {label: 'Efficiency (after COP)', unit: '%'}
        },
        :cost => {
          :purchase_price_per_unit =>
            {label: 'Initial purchase price', unit: 'euro'},
          :installing_costs_per_unit =>
            {label: 'Cost of installing', unit: 'euro'},
          :residual_value_per_unit =>
            {label: 'Residual value after lifetime', unit: 'euro'},
          :decommissioning_costs_per_unit =>
            {label: 'Decommissioning costs', unit: 'euro'},
          :fixed_yearly_operation_and_maintenance_costs_per_unit =>
            {label: 'Fixed operation and maintenance costs', unit: 'euro / year'}
        }
      })

      # If the converter belongs to the :cost_chps group then
      # add these
      CHP_VALUES  = SHARED_ATTRIBUTES.deep_merge({
        :technical => {
          :nominal_capacity_electricity_output_per_unit =>
            {label: 'Nominal electrical capacity', unit: 'MW'},
          :nominal_capacity_heat_output_per_unit =>
            {label: 'Nominal heat capacity', unit: 'MW'},
          :electricity_output_conversion =>
            {label: 'Electrical efficiency', unit: '%'},
          :heat_output_conversion  =>
            {label: 'Heat efficiency',  unit: '%'}
        },
        :cost => {
          :initial_investment_excl_ccs_per_unit =>
            {label: 'Initial investment (excl CCS)', unit: 'euro'},
          :additional_investment_ccs_per_unit =>
            {label: 'Additional inititial investment for CCS', unit: 'euro'},
          :decommissioning_costs_per_unit =>
            {label: 'Decommissioning costs', unit: 'euro'},
          :fixed_yearly_operation_and_maintenance_costs_per_unit =>
            {label: 'Fixed operation and maintenance costs', unit: 'euro / year'},
          :operation_and_maintenance_cost_variable_per_full_load_hour =>
            {label: 'Variable operation and maintenance costs (excl CCS)', unit: 'euro / full load hour'},
          :ccs_operation_and_maintenance_cost_per_full_load_hour =>
            {label: 'Additional variable operation and maintenance costs for CCS', unit: 'euro / full load hour'}
        },
        :other => {
          :construction_time =>
            {label: 'Construction time',  unit: 'year'}
        }
      })

      # some converters use extra attributes. Rather than messing up the views I
      # add the method here. I hope this will be removed
      def uses_coal_and_wood_pellets?
        carriers = @converter.input_carriers.map &:key
        carriers.include?(:coal) && carriers.include?(:wood_pellets)
      end

      # combines the *_VALUES hashes as needed. This is used in the converter
      # details page, in the /data section and through the API (v3)
      def attributes_to_show
        out = {}
        out = out.deep_merge HEAT_PRODUCTION_VALUES        if @converter.groups.include?(:cost_traditional_heat)
        out = out.deep_merge ELECTRICITY_PRODUCTION_VALUES if @converter.groups.include?(:cost_electricity_production)
        out = out.deep_merge HEAT_PUMP_VALUES              if @converter.groups.include?(:cost_heat_pumps)
        out = out.deep_merge CHP_VALUES                    if @converter.groups.include?(:cost_chps)

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

      # Here you can define the calculation methods to be shown. The groups are
      # merged
      def methods_to_show
        {
          :technical => {},
          :cost => {},
          :other => {}
          # :foo => { 'final_demand()' => {}}
        }
      end

      # Returns a giant nested hash with the methods and attributes to be shown
      #
      def attributes_and_methods_to_show
        attributes_to_show.deep_merge methods_to_show
      end
    end
  end
end