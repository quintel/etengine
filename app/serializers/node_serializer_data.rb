# frozen_string_literal: true

# This module defines which attributes and methods should be shown in the
# node detail popup. The API node detail requests shows this stuff
#
module NodeSerializerData
  FORMAT_KILO = ->(n) { (n / 1000).to_i }
  FORMAT_1DP = ->(n) { '%.1f' % n }
  FORMAT_FAC_TO_PERCENT = ->(n) { FORMAT_1DP.call(n * 100) }

  # If the node belongs to the electricity_production presentation group then
  # add these
  ELECTRICITY_PRODUCTION_ATTRIBUTES_AND_METHODS = {
    technical: {
      'electricity_output_capacity * number_of_units' => {
        label: 'Installed electrical capacity',
        key: :total_installed_electricity_capacity,
        unit: 'MW'
      },
      electricity_output_conversion: {
        label: 'Electrical efficiency',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
    },
    cost: {
      'total_investment_over_lifetime_per(:mw_electricity)' => {
        label: 'Investment over lifetime per MW',
        key: :total_investment_over_lifetime_per_mw_electricity,
        unit: 'EUR / MW',
        formatter: ->(n) { n.to_i }
      },
      'fixed_operation_and_maintenance_costs_per(:mw_electricity)' => {
        label: 'Fixed operation and maintenance costs',
        unit: 'EUR / MW / year',
        formatter: ->(n) { n.to_i }
      },
      :variable_operation_and_maintenance_costs_per_full_load_hour => {
        label: 'Variable operation and maintenance costs',
        unit: 'EUR / full load hour',
        formatter: ->(n) { n.to_i }
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      :takes_part_in_ets => {
        label: 'Do emissions have to be paid through the ETS?',
        unit: 'boolean',
        formatter: ->(x) { x == 1 }
      }
    },
    other: {
      technical_lifetime: {
        label: 'Technical lifetime',
        unit: 'years',
        formatter: ->(n) { n.to_i }
      }
    }
  }.freeze

  STEEL_ATTRIBUTES_AND_METHODS = {
    technical: {
    'number_of_units' => {
        label: 'Annual steel production',
        key: :annual_steel_production,
        unit: 'MT'
      }
    },
    cost: {
      'cost_of_capital_per(:plant) + depreciation_costs_per(:plant)' => {
        label: 'Annual CAPEX',
        key: :steel_fixed_costs_per_plant,
        unit: 'EUR / MT',
        formatter: ->(n) { n.to_i }
      },
      'fixed_operation_and_maintenance_costs_per(:plant)' => {
        label: 'Annual OPEX',
        key: :steel_fixed_operation_and_maintenance_costs_per_plant,
        unit: 'EUR / MT',
        formatter: ->(n) { n.to_i }
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      :takes_part_in_ets => {
        label: 'Do emissions have to be paid through the ETS?',
        unit: 'boolean',
        formatter: ->(x) { x == 1 }
      }
    },
    other: {
      technical_lifetime: {
        label: 'Technical lifetime',
        unit: 'years',
        formatter: ->(n) { n.to_i }
      }
    }
  }.freeze

  # If the node belongs to the electricity_production presentation group then
  # add these
  ELECTRICITY_PRODUCTION_CCS_ATTRIBUTES_AND_METHODS = {
    technical: {
      'electricity_output_capacity * number_of_units' => {
        label: 'Installed electrical capacity',
        key: :total_installed_electricity_capacity,
        unit: 'MW'
      },
      electricity_output_conversion: {
        label: 'Electrical efficiency',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
    },
    cost: {
      'initial_investment_per(:mw_electricity) + cost_of_installing_per(:mw_electricity) + decommissioning_costs_per(:mw_electricity)' => {
        label: 'Investment over lifetime per MW',
        key: :total_initial_investment_per_mw_electricity,
        unit: 'EUR / MW',
        formatter: ->(n) { n.to_i }
      },
      'ccs_investment_per(:mw_electricity)' => {
        label: 'Additional initial investment for CCS',
        unit: 'EUR / MW',
        formatter: ->(n) { n.to_i }
      },
      'fixed_operation_and_maintenance_costs_per(:mw_electricity)' => {
        label: 'Fixed operation and maintenance costs',
        unit: 'EUR / MW / year',
        formatter: ->(n) { n.to_i }
      },
      :variable_operation_and_maintenance_costs_per_full_load_hour => {
        label: 'Variable operation and maintenance costs (excl CCS)',
        unit: 'EUR / full load hour',
        formatter: ->(n) { n.to_i }
      },
      :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour => {
        label: 'Additional variable operation and maintenance costs for CCS',
        unit: 'EUR / full load hour',
        formatter: ->(n) { n.to_i }
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      :takes_part_in_ets => {
        label: 'Do emissions have to be paid through the ETS?',
        unit: 'boolean',
        formatter: ->(x) { x == 1 }
      }
    },
    other: {
      technical_lifetime: {
        label: 'Technical lifetime',
        unit: 'years',
        formatter: ->(n) { n.to_i }
      }
    }
  }.freeze

  WIND_SOLAR_COST_AND_OTHER = {
    cost: {
      'total_investment_over_lifetime_per(:mw_electricity)' => {
        label: 'Investment over lifetime per MW',
        key: :total_investment_over_lifetime_per_mw_electricity,
        unit: 'EUR / MW',
        formatter: ->(n) { n.to_i }
      },
      'fixed_operation_and_maintenance_costs_per(:mw_electricity)' => {
        label: 'Fixed operation and maintenance costs',
        unit: 'EUR / MW / year',
        formatter: ->(n) { n.to_i }
      },
      :variable_operation_and_maintenance_costs_per_full_load_hour => {
        label: 'Variable operation and maintenance costs',
        unit: 'EUR / full load hour',
        formatter: ->(n) { n.to_i }
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      :takes_part_in_ets => {
        label: 'Do emissions have to be paid through the ETS?',
        unit: 'boolean',
        formatter: ->(x) { x == 1 }
      }
    },
    other: {
      'land_use_per_unit / electricity_output_capacity' => {
        label: 'Land use',
        key: :land_use_per_unit_electricity_output_capacity,
        unit: 'km2 / MW'
      },
      technical_lifetime: {
        label: 'Technical lifetime',
        unit: 'years',
        formatter: ->(n) { n.to_i }
      }
    }
  }.freeze

  # If the node belongs to the solar_panel presentation group then
  # add these

  SOLAR_PANEL_ATTRIBUTES_AND_METHODS = {
    technical: {
      'electricity_output_capacity * number_of_units' => {
        label: 'Installed electrical capacity',
        key: :total_installed_electricity_capacity,
        unit: 'MW'
      },
      'electricity_output_capacity' => {
        label: 'Capacity per unit',
        key: :input_capacity,
        unit: 'MW'
      },
      electricity_output_conversion: {
        label: 'Electrical efficiency',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
    }
  }.merge(WIND_SOLAR_COST_AND_OTHER)

  # If the node belongs to the wind_solar_pv_plant presentation group then
  # add these

  SOLAR_PV_PLANT_ATTRIBUTES_AND_METHODS = {
    technical: {
      'electricity_output_capacity * number_of_units' => {
        label: 'Installed electrical capacity',
        key: :total_installed_electricity_capacity,
        unit: 'MW'
      },
      electricity_output_conversion: {
        label: 'Electrical efficiency',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
    }
  }.merge(WIND_SOLAR_COST_AND_OTHER)

  # If the node belongs to the wind_turbine presentation group then
  # add these

  WIND_TURBINE_ATTRIBUTES_AND_METHODS = {
    technical: {
      'electricity_output_capacity * number_of_units' => {
        label: 'Installed electrical capacity',
        key: :total_installed_electricity_capacity,
        unit: 'MW'
      },
      full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
    }
  }.merge(WIND_SOLAR_COST_AND_OTHER)

  # If the node belongs to the traditional_heat presentation group then
  # add these
  HEAT_PRODUCTION_ATTRIBUTES_AND_METHODS = {
    technical: {
      heat_output_conversion: {
        label: 'Heat efficiency (LHV)',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      heat_output_capacity: {
        label: 'Heat capacity per unit',
        unit: 'MW / unit',
        formatter: ->(n) { n.round(3) }
      },
      full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
    },
    cost: {
      'total_investment_over_lifetime_per(:plant)' => {
        label: 'Investment over lifetime per plant',
        key: :total_investment_over_lifetime_per_plant,
        unit: 'EUR / unit'
      },
      'fixed_operation_and_maintenance_costs_per(:plant)' => {
        label: 'Fixed operation and maintenance costs',
        unit: 'EUR / unit / year'
      },
      'variable_operation_and_maintenance_costs_per(:full_load_hour)' => {
        label: 'Variable operation and maintenance costs',
        unit: 'EUR / full load hour'
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      :takes_part_in_ets => {
        label: 'Do emissions have to be paid through the ETS?',
        unit: 'boolean',
        formatter: ->(x) { x == 1 }
      }
    },
    other: {
      technical_lifetime: { label: 'Technical lifetime', unit: 'years' }
    }
  }.freeze

  # If the node belongs to the heat_pumps presentation group then
  # add these
  HEAT_PUMP_ATTRIBUTES_AND_METHODS = {
    technical: {
      coefficient_of_performance: { label: 'Coefficient of Performance', unit: 'COP' },
      heat_output_capacity: {
        label: 'Heat capacity per unit',
        unit: 'MW / unit',
        formatter: ->(n) { n.round(3) }
      },
      full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
    },
    cost: {
      'total_investment_over_lifetime_per(:plant)' => {
        label: 'Investment over lifetime per plant',
        key: :total_investment_over_lifetime_per_plant,
        unit: 'EUR / unit'
      },
      'fixed_operation_and_maintenance_costs_per(:plant)' => {
        label: 'Fixed operation and maintenance costs',
        unit: 'EUR / unit / year'
      },
      'variable_operation_and_maintenance_costs_per(:full_load_hour)' => {
        label: 'Variable operation and maintenance costs',
        unit: 'EUR / full load hour'
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      :takes_part_in_ets => {
        label: 'Do emissions have to be paid through the ETS?',
        unit: 'boolean',
        formatter: ->(x) { x == 1 }
      }
    },
    other: {
      technical_lifetime: { label: 'Technical lifetime', unit: 'years' }
    }
  }.freeze

  # If the node belongs to the chps presentation group then
  # add these
  CHP_ATTRIBUTES_AND_METHODS = {
    technical: {
      'electricity_output_capacity * number_of_units' => {
        label: 'Installed electrical capacity',
        key: :total_installed_electricity_capacity,
        unit: 'MW'
      },
      electricity_output_conversion: {
        label: 'Electrical efficiency',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      heat_output_conversion: {
        label: 'Heat efficiency',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
    },
    cost: {
      'total_investment_over_lifetime_per(:mw_electricity)' => {
        label: 'Investment over lifetime per MW',
        key: :total_investment_over_lifetime_per_mw_electricity,
        unit: 'EUR / MW',
        formatter: ->(n) { n.to_i }
      },
      'fixed_operation_and_maintenance_costs_per(:mw_electricity)' => {
        label: 'Fixed operation and maintenance costs',
        unit: 'EUR / MW / year',
        formatter: ->(n) { n.to_i }
      },
      :variable_operation_and_maintenance_costs_per_full_load_hour => {
        label: 'Variable operation and maintenance costs',
        unit: 'EUR / full load hour',
        formatter: ->(n) { n.to_i }
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      :takes_part_in_ets => {
        label: 'Do emissions have to be paid through the ETS?',
        unit: 'boolean',
        formatter: ->(x) { x == 1 }
      }
    },
    other: {
      technical_lifetime: { label: 'Technical lifetime', unit: 'years' }
    }
  }.freeze

  # If the node belongs to the hydrogen_production presentation group then
  # add these
  HYDROGEN_PRODUCTION_ATTRIBUTES_AND_METHODS = {
    technical: {
      'input_capacity * number_of_units' => {
        label: 'Installed input capacity',
        key: :total_installed_input_capacity,
        unit: 'MW'
      },
      hydrogen_output_conversion: {
        label: 'Hydrogen output efficiency',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      full_load_hours: { label: 'Full load hours', unit: 'hour / year' },
      free_co2_factor: { label: 'CCS capture rate', unit: '%', formatter: FORMAT_FAC_TO_PERCENT }
    },
    cost: {
      'initial_investment_per(:mw_input_capacity) + cost_of_installing_per(:mw_input_capacity) + decommissioning_costs_per(:mw_input_capacity)' => {
        label: 'Investment over lifetime per MW input',
        key: :total_initial_investment_per_mw_input_capacity,
        unit: 'EUR / MW',
        formatter: ->(n) { n.to_i }
      },
      'ccs_investment_per(:mw_input_capacity)' => {
        label: 'Additional initial investment for CCS',
        key: :ccs_investment_per_mw_input_capacity,
        unit: 'EUR / MW',
        formatter: ->(n) { n.to_i }
      },
      'fixed_operation_and_maintenance_costs_per(:mw_input_capacity)' => {
        label: 'Fixed operation and maintenance costs',
        key: :fixed_operation_and_maintenance_costs_per_mw_input_capacity,
        unit: 'EUR / MW / year',
        formatter: ->(n) { n.to_i }
      },
      'variable_operation_and_maintenance_costs_per(:full_load_hour)' => {
        label: 'Variable operation and maintenance costs',
        unit: 'EUR / full load hour'
      },
      :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour => {
        label: 'Additional variable operation and maintenance costs for CCS',
        unit: 'EUR / full load hour'
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      :takes_part_in_ets => {
        label: 'Do emissions have to be paid through the ETS?',
        unit: 'boolean',
        formatter: ->(x) { x == 1 }
      }
    },
    other: {
      technical_lifetime: {
        label: 'Technical lifetime',
        unit: 'years',
        formatter: ->(n) { n.to_i }
      }
    }
  }.freeze

  FLEXIBILITY_COSTS_AND_OTHER = {
    cost: {
      'total_investment_over_lifetime_per(:mw_input_capacity)' => {
        label: 'Investment over lifetime per MW input',
        key: :total_investment_over_lifetime_per_mw_input_capacity,
        unit: 'EUR / MW',
        formatter: ->(n) { n.to_i }
      },
      'fixed_operation_and_maintenance_costs_per(:mw_input_capacity)' => {
        label: 'Fixed operation and maintenance costs',
        unit: 'EUR / MW / year',
        formatter: ->(n) { n.to_i }
      },
      :variable_operation_and_maintenance_costs_per_full_load_hour => {
        label: 'Variable operation and maintenance costs',
        unit: 'EUR / full load hour',
        formatter: ->(n) { n.to_i }
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      :takes_part_in_ets => {
        label: 'Do emissions have to be paid through the ETS?',
        unit: 'boolean',
        formatter: ->(x) { x == 1 }
      }
    },
    other: {
      technical_lifetime: {
        label: 'Technical lifetime',
        unit: 'years',
        formatter: ->(n) { n.to_i }
      }
    }
  }.freeze

  # If the node belongs to the p2g presentation group then
  # add these
  P2G_ATTRIBUTES_AND_METHODS =
    {
      technical: {
        'input_capacity * number_of_units': {
          label: 'Installed capacity',
          key: :total_installed_capacity,
          unit: 'MWe'
        },
        hydrogen_output_conversion: {
          label: 'Hydrogen output efficiency',
          unit: '%',
          formatter: FORMAT_FAC_TO_PERCENT
        },
        full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
      }
    }.merge(FLEXIBILITY_COSTS_AND_OTHER)

  # If the node belongs to the p2h presentation group then
  # add these
  P2H_ATTRIBUTES_AND_METHODS =
    {
      technical: {
        'input_capacity * number_of_units': {
          label: 'Installed capacity',
          key: :total_installed_capacity,
          unit: 'MWe'
        },
        heat_output_conversion: {
          label: 'Heat efficiency',
          unit: '%',
          formatter: FORMAT_FAC_TO_PERCENT
        },
        full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
      }
    }.merge(FLEXIBILITY_COSTS_AND_OTHER)

  # If the node belongs to the p2kerosene presentation group then
  # add these
  P2KEROSENE_ATTRIBUTES_AND_METHODS =
    {
      technical: {
        'input_capacity * number_of_units' => {
          label: 'Installed capacity',
          key: :total_installed_capacity,
          unit: 'MWe'
        },
        kerosene_output_conversion: {
          label: 'Kerosene output efficiency',
          unit: '%',
          formatter: FORMAT_FAC_TO_PERCENT
        },
        full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
      }
    }.merge(FLEXIBILITY_COSTS_AND_OTHER)

  # If the node belongs to the p2p presentation group then
  # add these
  P2P_ATTRIBUTES_AND_METHODS =
    {
      technical: {
        'input_capacity * number_of_units' => {
          label: 'Installed capacity',
          key: :total_installed_capacity,
          unit: 'MW'
        },
        'storage[:volume] * number_of_units' => {
          label: 'Total storage capacity',
          key: :total_storage_capacity,
          unit: 'MWh'
        },
        '1.0/electricity_input_conversion * electricity_output_conversion' => {
          label: 'Round trip efficiency',
          key: :round_trip_efficiency,
          unit: '%',
          formatter: FORMAT_FAC_TO_PERCENT
        }
      }
    }.merge(FLEXIBILITY_COSTS_AND_OTHER)

  # If the node belongs to the V2G presentation group then
  # add these
  V2G_ATTRIBUTES_AND_METHODS = {
    technical: {
      :electricity_output_conversion => {
        label: 'Round trip efficiency',
        key: :round_trip_efficiency,
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      }
    }
  }.freeze

  CO2_GENERIC_ATTRIBUTES_AND_METHODS = {
    cost: {
      'total_initial_investment_per(:plant)' => {
        label: 'Initial investment',
        unit: 'EUR / unit'
      },
      'fixed_operation_and_maintenance_costs_per(:plant)' => {
        label: 'Fixed operation and maintenance costs',
        unit: 'EUR / unit / year'
      },
      :variable_operation_and_maintenance_costs_per_full_load_hour => {
        label: 'Variable operation and maintenance costs',
        unit: 'EUR / full load hour',
        formatter: ->(n) { n.to_i }
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      }
    },
    other: {
      technical_lifetime: { label: 'Economic lifetime', unit: 'years', formatter: ->(n) { n.to_i } }
    }
  }.freeze

  CO2_CAPTURE_ATTRIBUTES_AND_METHODS =
    {
      technical: {
        'input_capacity * full_load_hours * number_of_units' => {
          label: 'Total installed capture capacity',
          key: :total_installed_capture_capacity,
          unit: 'T_CO2 / year',
          formatter: FORMAT_KILO
        },
        'input_capacity * full_load_hours' => {
          label: 'Capture capacity per unit',
          key: :input_capacity_co2_capture,
          unit: 'T_CO2 / year',
          formatter: FORMAT_KILO
        },
        full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
      }
    }.merge(CO2_GENERIC_ATTRIBUTES_AND_METHODS)

  CO2_STORAGE_ATTRIBUTES_AND_METHODS =
    {
      technical: {
        'input_capacity * full_load_hours * number_of_units' => {
          label: 'Total installed storage capacity',
          key: :total_installed_storage_capacity,
          unit: 'T_CO2 / year',
          formatter: FORMAT_KILO
        },
        'input_capacity * full_load_hours' => {
          label: 'Storage capacity per unit',
          key: :input_capacity_co2_storage,
          unit: 'T_CO2 / year',
          formatter: FORMAT_KILO
        },
        full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
      }
    }.merge(CO2_GENERIC_ATTRIBUTES_AND_METHODS)

  CO2_TRANSPORT_ATTRIBUTES_AND_METHODS =
    {
      technical: {
        'input_capacity * full_load_hours * number_of_units' => {
          label: 'Total installed transport capacity',
          key: :total_installed_transport_capacity,
          unit: 'T_CO2 / year',
          formatter: FORMAT_KILO
        },
        'input_capacity * full_load_hours' => {
          label: 'Transport capacity per unit',
          key: :input_capacity_co2_transport,
          unit: 'T_CO2 / year',
          formatter: FORMAT_KILO
        },
        full_load_hours: { label: 'Full load hours', unit: 'hour / year' }
      }
    }.merge(CO2_GENERIC_ATTRIBUTES_AND_METHODS)

  # If the node belongs to the traditional_heat presentation group then
  # add these
  BIOMASS_ATTRIBUTES_AND_METHODS = {
    technical: {
      'input_capacity * number_of_units' => {
        label: 'Installed input capacity',
        key: :total_installed_input_capacity,
        unit: 'MW'
      },
      :full_load_hours => { label: 'Full load hours', unit: 'hour / year' },
      '1.0 - loss_output_conversion' => {
        label: 'Efficiency',
        key: :efficiency,
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      }
    },
    cost: {
      'total_investment_over_lifetime_per(:mw_input_capacity)' => {
        label: 'Investment over lifetime per MW input',
        key: :total_investment_over_lifetime_per_mw_input_capacity,
        unit: 'EUR / MW',
        formatter: ->(n) { n.to_i }
      },
      'fixed_operation_and_maintenance_costs_per(:mw_input_capacity)' => {
        label: 'Fixed operation and maintenance costs',
        key: :fixed_operation_and_maintenance_costs_per_mw_input_capacity,
        unit: 'EUR / MW / year',
        formatter: ->(n) { n.to_i }
      },
      'variable_operation_and_maintenance_costs_per(:full_load_hour)' => {
        label: 'Variable operation and maintenance costs',
        unit: 'EUR / full load hour'
      },
      :wacc => {
        label: 'Weighted average cost of capital',
        unit: '%',
        formatter: FORMAT_FAC_TO_PERCENT
      },
      :takes_part_in_ets => {
        label: 'Do emissions have to be paid through the ETS?',
        unit: 'boolean',
        formatter: ->(x) { x == 1 }
      }
    },
    other: {
      technical_lifetime: { label: 'Technical lifetime', unit: 'years' }
    }
  }.freeze

  # some nodes use extra attributes. Rather than messing up the views I
  # add the method here. I hope this will be removed
  def uses_coal_and_wood_pellets?
    carriers = @node.input_carriers.map(&:key)
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
      when :electricity_production_ccs
        ELECTRICITY_PRODUCTION_CCS_ATTRIBUTES_AND_METHODS
      when :solar_panel
        SOLAR_PANEL_ATTRIBUTES_AND_METHODS
      when :solar_pv_plant
        SOLAR_PV_PLANT_ATTRIBUTES_AND_METHODS
      when :wind_turbine
        WIND_TURBINE_ATTRIBUTES_AND_METHODS
      when :heat_pumps
        HEAT_PUMP_ATTRIBUTES_AND_METHODS
      when :chps
        CHP_ATTRIBUTES_AND_METHODS
      when :hydrogen_production
        HYDROGEN_PRODUCTION_ATTRIBUTES_AND_METHODS
      when :co2_capture
        CO2_CAPTURE_ATTRIBUTES_AND_METHODS
      when :co2_storage
        CO2_STORAGE_ATTRIBUTES_AND_METHODS
      when :co2_transport
        CO2_TRANSPORT_ATTRIBUTES_AND_METHODS
      when :p2g
        P2G_ATTRIBUTES_AND_METHODS
      when :p2h
        P2H_ATTRIBUTES_AND_METHODS
      when :p2kerosene
        P2KEROSENE_ATTRIBUTES_AND_METHODS
      when :p2p
        P2P_ATTRIBUTES_AND_METHODS
      when :v2g
        V2G_ATTRIBUTES_AND_METHODS
      when :biomass
        BIOMASS_ATTRIBUTES_AND_METHODS
      when :steel
        STEEL_ATTRIBUTES_AND_METHODS
      else
        {}
      end

    # custom stuff, trying to keep the view simple
    if uses_coal_and_wood_pellets?
      out = out.dup
      out[:current_fuel_input_mix] = {}
      fuel_mix = {}
      @node.input_edges.each do |edge|
        fuel_mix["#{edge.carrier.key}_input_conversion"] = {
          label: edge.carrier.key.to_s.humanize,
          unit: '%',
          formatter: FORMAT_FAC_TO_PERCENT
        }
      end
      out[:current_fuel_input_mix] = fuel_mix
    end
    out
  end
end
