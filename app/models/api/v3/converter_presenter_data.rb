module Api
  module V3
    # This module defines which attributes and methods should be shown in the
    # converter detail popup. The API converter detail requests shows this stuff
    #
    module ConverterPresenterData
      FORMAT_KILO           = ->(n) { (n / 1000).to_i }
      FORMAT_1DP            = ->(n) { '%.1f' % n }
      FORMAT_FAC_TO_PERCENT = ->(n) { FORMAT_1DP.call(n * 100) }

      # If the converter belongs to the :cost_electricity_production group then
      # add these
      ELECTRICITY_PRODUCTION_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :electricity_output_capacity =>
            { label: 'Electrical capacity', unit:'MW',
              formatter: FORMAT_1DP },
          :electricity_output_conversion  =>
            { label: 'Electrical efficiency', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT },
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          :heat_output_conversion  =>
            { label: 'Heat efficiency', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT }
        },
        :cost => {
          'initial_investment_per(:mw_electricity)' =>
            { label: 'Initial investment (excl CCS)', unit: 'kEUR / MWe',
              formatter: FORMAT_KILO },
          'ccs_investment_per(:mw_electricity)' =>
            { label: 'Additional inititial investment for CCS', unit: 'kEUR / MWe',
              formatter: FORMAT_KILO },
          'decommissioning_costs_per(:mw_electricity)' =>
            { label: 'Decommissioning costs', unit:'kEUR / MWe',
              formatter: FORMAT_KILO },
          'fixed_operation_and_maintenance_costs_per(:mw_electricity)' =>
            { label: 'Fixed operation and maintenance costs', unit:'kEUR / MWe / year',
              formatter: ->(n) { '%.2f' % (n / 1000) } },
          :variable_operation_and_maintenance_costs_per_full_load_hour  =>
            { label: 'Variable operation and maintenance costs (excl CCS)', unit: 'EUR / full load hour',
              formatter: ->(n) { n.to_i } },
          :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour  =>
            { label: 'Additional variable operation and maintenance costs for CCS', unit: 'EUR / full load hour',
              formatter: ->(n) { n.to_i } },
          :wacc  =>
            {label: 'Weighted average cost of capital', unit: '%'},
          :takes_part_in_ets  =>
            {label: 'Do emissions have to be paid through the ETS?', unit: 'yes / no', formatter: lambda{|x| x == 1 ? 'yes' : 'no'}}
        },
        :other => {
          :land_use_per_unit  =>
            {label: 'Land use per unit', unit: 'km2'},
          :construction_time  =>
            { label: 'Construction time', unit: 'years',
              formatter: FORMAT_1DP },
          :technical_lifetime  =>
            { label: 'Technical lifetime', unit: 'years',
              formatter: ->(n) { n.to_i } }
        }
      }

      # If the converter belongs to the :cost_traditional_heat group then
      # add these
      HEAT_PRODUCTION_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :heat_output_capacity =>
            { label: 'Heat capacity', unit:'MW',
              formatter: FORMAT_1DP },
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          :heat_output_conversion  =>
            { label: 'Heat efficiency', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT }
        },
        :cost => {
          'initial_investment_per(:plant)' =>
            {label: 'Initial purchase price', unit: 'EUR'},
          'cost_of_installing_per(:plant)' =>
            {label: 'Cost of installing', unit:'EUR'},
          'decommissioning_costs_per(:plant)' =>
            {label: 'Decommissioning costs', unit:'EUR'},
          'fixed_operation_and_maintenance_costs_per(:plant)' =>
            {label: 'Fixed operation and maintenance costs', unit:'EUR / year'},
          'variable_operation_and_maintenance_costs_per(:full_load_hour)'  =>
            {label: 'Variable operation and maintenance costs', unit: 'EUR / full load hour'},
          :wacc  =>
            {label: 'Weighted average cost of capital', unit: '%'},
          :takes_part_in_ets  =>
            {label: 'Do emissions have to be paid through the ETS?', unit: 'yes / no', formatter: lambda{|x| x == 1 ? 'yes' : 'no'}}
        },
        :other => {
          :land_use_per_unit  =>
            {label: 'Land use per unit', unit: 'km2'},
          :technical_lifetime  =>
            {label: 'Technical lifetime', unit: 'years'}
        }
      }

      # If the converter belongs to the :cost_heat_pumps group then
      # add these
      HEAT_PUMP_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :heat_output_capacity =>
            {label: 'Heat capacity', unit:'MW'},
          :coefficient_of_performance =>
            {label: 'Coefficient of Performance',  unit:''},
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          :heat_and_cold_output_conversion  =>
            { label: 'Efficiency (after COP)', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT }
        },
        :cost => {
          'initial_investment_per(:plant)' =>
            {label: 'Initial purchase price', unit: 'EUR'},
          'cost_of_installing_per(:plant)' =>
            {label: 'Cost of installing', unit:'EUR'},
          'decommissioning_costs_per(:plant)' =>
            {label: 'Decommissioning costs', unit:'EUR'},
          'fixed_operation_and_maintenance_costs_per(:plant)' =>
            {label: 'Fixed operation and maintenance costs', unit:'EUR / year'},
          'variable_operation_and_maintenance_costs_per(:full_load_hour)'  =>
            {label: 'Variable operation and maintenance costs', unit: 'EUR / full load hour'},
          :wacc  =>
            {label: 'Weighted average cost of capital', unit: '%'},
          :takes_part_in_ets  =>
            {label: 'Do emissions have to be paid through the ETS?', unit: 'yes / no', formatter: lambda{|x| x == 1 ? 'yes' : 'no'}}
        },
        :other => {
          :land_use_per_unit  =>
            {label: 'Land use per unit', unit: 'km2'},
          :technical_lifetime  =>
            {label: 'Technical lifetime', unit: 'years'}
        }
      }

      # If the converter belongs to the :cost_chps group then
      # add these
      CHP_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :electricity_output_capacity =>
            { label: 'Electrical capacity', unit:'MW',
              formatter: FORMAT_1DP },
          :electricity_output_conversion  =>
            { label: 'Electrical efficiency', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT },
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          :heat_output_conversion  =>
            { label: 'Heat efficiency', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT }
        },
        :cost => {
          'initial_investment_per(:mw_electricity)' =>
            { label: 'Initial investment (excl CCS)', unit: 'kEUR / MWe',
              formatter: FORMAT_KILO },
          'ccs_investment_per(:mw_electricity)' =>
            { label: 'Additional inititial investment for CCS', unit: 'kEUR / MWe',
              formatter: FORMAT_KILO },
          'decommissioning_costs_per(:mw_electricity)' =>
            { label: 'Decommissioning costs', unit:'kEUR / MWe',
              formatter: FORMAT_KILO },
          'fixed_operation_and_maintenance_costs_per(:mw_electricity)' =>
            { label: 'Fixed operation and maintenance costs', unit:'kEUR / MWe / year',
              formatter: ->(n) { '%.2f' % (n / 1000) } },
          :variable_operation_and_maintenance_costs_per_full_load_hour  =>
            { label: 'Variable operation and maintenance costs (excl CCS)', unit: 'EUR / full load hour',
              formatter: ->(n) { n.to_i } },
          :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour  =>
            { label: 'Additional variable operation and maintenance costs for CCS', unit: 'EUR / full load hour',
              formatter: ->(n) { n.to_i } },
          :wacc  =>
            {label: 'Weighted average cost of capital', unit: '%'},
          :takes_part_in_ets  =>
            {label: 'Do emissions have to be paid through the ETS?', unit: 'yes / no', formatter: lambda{|x| x == 1 ? 'yes' : 'no'}}
        },
        :other => {
          :land_use_per_unit  =>
            {label: 'Land use per unit', unit: 'km2'},
          :construction_time =>
            {label: 'Construction time',  unit: 'years'},
          :technical_lifetime  =>
            {label: 'Technical lifetime', unit: 'years'}
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
        out = {}
        out = HEAT_PRODUCTION_ATTRIBUTES_AND_METHODS        if @converter.groups.include?(:cost_traditional_heat)
        out = ELECTRICITY_PRODUCTION_ATTRIBUTES_AND_METHODS if @converter.groups.include?(:cost_electricity_production)
        out = HEAT_PUMP_ATTRIBUTES_AND_METHODS              if @converter.groups.include?(:cost_heat_pumps)
        out = CHP_ATTRIBUTES_AND_METHODS                    if @converter.groups.include?(:cost_chps)

        # custom stuff, trying to keep the view simple
        if uses_coal_and_wood_pellets?
          out = out.dup
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
