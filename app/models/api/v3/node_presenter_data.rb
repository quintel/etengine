module Api
  module V3
    # This module defines which attributes and methods should be shown in the
    # node detail popup. The API node detail requests shows this stuff
    #
    module NodePresenterData
      FORMAT_KILO           = ->(n) { (n / 1000).to_i }
      FORMAT_1DP            = ->(n) { '%.1f' % n }
      FORMAT_FAC_TO_PERCENT = ->(n) { FORMAT_1DP.call(n * 100) }

      # If the node belongs to the electricity_production presentation group then
      # add these
      ELECTRICITY_PRODUCTION_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :electricity_output_capacity =>
            { label: 'Electrical capacity per unit', unit: 'MW',
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
          'total_initial_investment_per(:mw_electricity)' =>
            { label: 'Initial investment (excl CCS)', unit: 'kEUR / MWe',
              formatter: FORMAT_KILO },
          'ccs_investment_per(:mw_electricity)' =>
            { label: 'Additional initial investment for CCS', unit: 'kEUR / MWe',
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

      # If the node belongs to the traditional_heat presentation group then
      # add these
      HEAT_PRODUCTION_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :heat_output_capacity =>
            { label: 'Heat capacity per unit', unit: 'MW',
              formatter: FORMAT_1DP },
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          :heat_output_conversion  =>
            { label: 'Heat efficiency', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT }
        },
        :cost => {
          'total_initial_investment_per(:plant)' =>
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

      # If the node belongs to the heat_pumps presentation group then
      # add these
      HEAT_PUMP_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :heat_output_capacity =>
            {label: 'Heat capacity per unit', unit: 'MW'},
          :coefficient_of_performance =>
            {label: 'Coefficient of Performance',  unit:''},
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          :heat_and_cold_output_conversion  =>
            { label: 'Efficiency (after COP)', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT }
        },
        :cost => {
          'total_initial_investment_per(:plant)' =>
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

      # If the node belongs to the chps presentation group then
      # add these
      CHP_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :electricity_output_capacity =>
            { label: 'Electrical capacity per unit', unit: 'MW',
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
          'total_initial_investment_per(:mw_electricity)' =>
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

      # If the node belongs to the hydrogen_production presentation group then
      # add these
      HYDROGEN_PRODUCTION_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :typical_input_capacity =>
            { label: 'Capacity per unit', unit: 'MW input',
              formatter: ->(n) { n && FORMAT_1DP.call(n) } },
          :hydrogen_output_conversion  =>
            { label: 'Hydrogen output efficiency', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT },
          :full_load_hours  =>
            { label: 'Full load hours', unit: 'hour / year'},
          :free_co2_factor =>
            { label: 'CCS capture rate', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT }
        },
        :cost => {
          'total_initial_investment_per(:plant)' =>
            { label: 'Investment costs', unit: 'EUR'},
          'ccs_investment_per(:plant)' =>
            { label: 'Additional initial investment for CCS', unit: 'EUR'},
          'fixed_operation_and_maintenance_costs_per(:plant)' =>
            { label: 'Fixed operation and maintenance costs', unit:'EUR / year'},
          'variable_operation_and_maintenance_costs_per(:full_load_hour)'  =>
            { label: 'Variable operation and maintenance costs', unit: 'EUR / full load hour'},
          :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour  =>
            { label: 'Additional variable operation and maintenance costs for CCS', unit: 'EUR / full load hour'},
          :wacc  =>
            { label: 'Weighted average cost of capital', unit: '%'},
          :takes_part_in_ets  =>
            { label: 'Do emissions have to be paid through the ETS?', unit: 'yes / no', formatter: lambda{|x| x == 1 ? 'yes' : 'no'}}
        },
        :other => {
          :land_use_per_unit  =>
            { label: 'Land use per unit', unit: 'km2'},
          :construction_time  =>
            { label: 'Construction time', unit: 'years',
              formatter: FORMAT_1DP },
          :technical_lifetime  =>
            { label: 'Technical lifetime', unit: 'years',
              formatter: ->(n) { n.to_i } }
        }
      }

      FLEXIBILITY_COSTS_AND_OTHER = {
        :cost => {
          'total_initial_investment_per(:mw_typical_input_capacity)' =>
            { label: 'Initial investment (excl CCS)', unit: 'kEUR / MWe',
              formatter: FORMAT_KILO },
          'ccs_investment_per(:mw_typical_input_capacity)' =>
            { label: 'Additional inititial investment for CCS', unit: 'kEUR / MWe',
              formatter: FORMAT_KILO },
          'decommissioning_costs_per(:mw_typical_input_capacity)' =>
            { label: 'Decommissioning costs', unit:'kEUR / MWe',
              formatter: FORMAT_KILO },
          'fixed_operation_and_maintenance_costs_per(:mw_typical_input_capacity)' =>
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

      # If the node belongs to the carbon_capturing presentation group then
      # add these
      CARBON_CAPTURING_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :typical_input_capacity =>
            { label: 'Capacity per unit', unit: 'MWe',
              formatter: FORMAT_1DP },
          :co_output_conversion=>
            { label: 'Carbon monoxide output efficiency', unit: '%',
            formatter: FORMAT_FAC_TO_PERCENT },
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
        }
      }.merge(FLEXIBILITY_COSTS_AND_OTHER)

      # If the node belongs to the p2g presentation group then
      # add these
      P2G_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :typical_input_capacity =>
            { label: 'Capacity per unit', unit: 'MWe',
              formatter: FORMAT_1DP },
          :hydrogen_output_conversion=>
            { label: 'Hydrogen output efficiency', unit: '%',
            formatter: FORMAT_FAC_TO_PERCENT },
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
        }
      }.merge(FLEXIBILITY_COSTS_AND_OTHER)

      # If the node belongs to the p2h presentation group then
      # add these
      P2H_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :typical_input_capacity =>
            { label: 'Capacity per unit', unit: 'MWe',
              formatter: FORMAT_1DP },
          :useable_heat_output_conversion=>
            { label: 'Heat efficiency', unit: '%',
            formatter: FORMAT_FAC_TO_PERCENT },
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
        }
      }.merge(FLEXIBILITY_COSTS_AND_OTHER)

      # If the node belongs to the p2kerosene presentation group then
      # add these
      P2KEROSENE_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :typical_input_capacity =>
            { label: 'Capacity per unit', unit: 'MWe',
              formatter: FORMAT_1DP },
          :kerosene_output_conversion=>
            { label: 'Kerosene output efficiency', unit: '%',
            formatter: FORMAT_FAC_TO_PERCENT },
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
        }
      }.merge(FLEXIBILITY_COSTS_AND_OTHER)

      # If the node belongs to the p2p presentation group then
      # add these
      P2P_ATTRIBUTES_AND_METHODS = {
        technical: {
          typical_input_capacity: {
            label: 'Charging capacity per unit',
            unit: 'MW'
          },
          'storage[:volume]' => {
            label: 'Storage capacity per unit',
            unit: 'MWh'
          },
          '1.0/electricity_input_conversion * electricity_output_conversion' => {
            label: 'Round trip efficiency',
            unit: '%',
            formatter: FORMAT_FAC_TO_PERCENT
          }
        }
      }.merge(FLEXIBILITY_COSTS_AND_OTHER)

      # If the node belongs to the traditional_heat presentation group then
      # add these
      BIOMASS_ATTRIBUTES_AND_METHODS = {
        :technical => {
          :typical_input_capacity =>
            { label: 'Capacity per unit', unit: 'MW',
              formatter: FORMAT_1DP },
          :full_load_hours  =>
            {label: 'Full load hours', unit: 'hour / year'},
          '1.0 - loss_output_conversion' =>
            { label: 'Efficiency', unit: '%',
              formatter: FORMAT_FAC_TO_PERCENT }
        },
        :cost => {
          'total_initial_investment_per(:plant)' =>
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

      # some nodes use extra attributes. Rather than messing up the views I
      # add the method here. I hope this will be removed
      def uses_coal_and_wood_pellets?
        carriers = @node.input_carriers.map &:key
        carriers.include?(:coal) && carriers.include?(:wood_pellets)
      end

      # combines the *_VALUES hashes as needed. This is used in the node
      # details page, in the /data section and through the API (v3)
      def attributes_and_methods_to_show
        out =
          case @node.presentation_group
          when :traditional_heat
            HEAT_PRODUCTION_ATTRIBUTES_AND_METHODS
          when :electricity_production
            ELECTRICITY_PRODUCTION_ATTRIBUTES_AND_METHODS
          when :heat_pumps
            HEAT_PUMP_ATTRIBUTES_AND_METHODS
          when :chps
            CHP_ATTRIBUTES_AND_METHODS
          when :hydrogen_production
            HYDROGEN_PRODUCTION_ATTRIBUTES_AND_METHODS
          when :carbon_capturing
            CARBON_CAPTURING_ATTRIBUTES_AND_METHODS
          when :p2g
            P2G_ATTRIBUTES_AND_METHODS
          when :p2h
            P2H_ATTRIBUTES_AND_METHODS
          when :p2kerosene
            P2KEROSENE_ATTRIBUTES_AND_METHODS
          when :p2p
            P2P_ATTRIBUTES_AND_METHODS
          when :biomass
            BIOMASS_ATTRIBUTES_AND_METHODS
          else
            {}
          end

        # custom stuff, trying to keep the view simple
        if uses_coal_and_wood_pellets?
          out = out.dup
          out[:current_fuel_input_mix] = {}
          fuel_mix = {}
          @node.input_links.each do |link|
            fuel_mix["#{link.carrier.key}_input_conversion"] = {label: link.carrier.key.to_s.humanize, unit: '%'}
          end
          out[:current_fuel_input_mix] = fuel_mix
        end
        out
      end
    end
  end
end
