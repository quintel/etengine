class Qernel::ConverterApi

  # The required installed input capacity, based on the demand.
  def mwh_input
    dataset_fetch_handle_nil(:mwh_input) do
      demand / SECS_PER_HOUR
    end
  end
  attributes_required_for :mwh_input, [:demand]

  # The output of electricity expressed in MWh.
  def mwh_electricy_output
    dataset_fetch_handle_nil(:mwh_electricy_output) do
      output_of_electricity / SECS_PER_HOUR
    end
  end
  attributes_required_for :mwh_electricy_output, [:output_of_electricity]

  # Determines the average typical input capacity over its lifetime, accounting for the loss in nominal capacity over its lifetime.
  #
  def typical_input_capacity_in_mw
    dataset_fetch_handle_nil(:typical_input_capacity_in_mw) do
      typical_nominal_input_capacity * average_effective_output_of_nominal_capacity_over_lifetime
    end
  end
  attributes_required_for :typical_input_capacity_in_mw, [
    :typical_nominal_input_capacity,
    :average_effective_output_of_nominal_capacity_over_lifetime
  ]
  # TODO: get rid of the alias
  alias typical_input_capacity typical_input_capacity_in_mw

  ## Returns the nominal electrical capicity of one unit.
  #
  def nominal_capacity_electricity_output_per_unit
    dataset_fetch_handle_nil(:nominal_capacity_electricity_output_per_unit) do
      typical_nominal_input_capacity * electricity_output_conversion
    end
  end
  attributes_required_for :nominal_capacity_electricity_output_per_unit, [
    :typical_nominal_input_capacity,
    :electricity_output_conversion
  ]

  ## Returns the nominal heat capicity of one unit. This is both useable heat as steam_hot_water.
  #
  def nominal_capacity_heat_output_per_unit
    dataset_fetch_handle_nil(:nominal_capacity_heat_output_per_unit) do
      typical_nominal_input_capacity * heat_output_conversion
    end
  end
  attributes_required_for :nominal_capacity_heat_output_per_unit, [
    :typical_nominal_input_capacity,
    :heat_output_conversion
  ]

  ## Returns the nominal cooling capacity of one unit
  #
  def nominal_capacity_cooling_output_per_unit
    dataset_fetch_handle_nil(:nominal_capacity_cooling_output_per_unit) do
      typical_nominal_input_capacity * cooling_output_conversion
    end
  end
  attributes_required_for :nominal_capacity_cooling_output_per_unit, [
    :typical_nominal_input_capacity,
    :cooling_output_conversion
  ]

  ## Returns the total heat output conversion of one unit. This is useable heat, steam_hot_water and hot_water.
  #
  def heat_output_conversion
    dataset_fetch_handle_nil(:heat_output_conversion) do
      (steam_hot_water_output_conversion + hot_water_output_conversion + useable_heat_output_conversion)
    end
  end
  attributes_required_for :heat_output_conversion, [
    :steam_hot_water_output_conversion,
    :useable_heat_output_conversion,
    :hot_water_output_conversion
  ]

  ## Returns the total heat and cold output conversion of one unit. This is useable heat, steam_hot_water, hot_water and cooling.
  #
  def heat_and_cold_output_conversion
    dataset_fetch_handle_nil(:heat_and_cold_output_conversion) do
      (steam_hot_water_output_conversion + hot_water_output_conversion + useable_heat_output_conversion + cooling_output_conversion)
    end
  end
  attributes_required_for :heat_and_cold_output_conversion, [
    :steam_hot_water_output_conversion,
    :useable_heat_output_conversion,
    :hot_water_output_conversion,
    :cooling_output_conversion
  ]


  def coefficient_of_performance
    dataset_fetch_handle_nil(:coefficient_of_performance) do
      (1 / (1 - ( ambient_heat_input_conversion + ambient_cold_input_conversion + geothermal_input_conversion)))
    end
  end

  attributes_required_for :coefficient_of_performance, [
    :ambient_heat_input_conversion,
    :ambient_cold_input_conversion
  ]

  # How many seconds a year the converters runs at full load.
  # This is useful because MJ is MW per second.
  def full_load_seconds
    dataset_fetch_handle_nil(:full_load_seconds) do
      full_load_hours * SECS_PER_HOUR
    end
  end
  attributes_required_for :full_load_seconds, [:full_load_hours]

  def production_based_on_number_of_units
    handle_nil(:production_based_on_number_of_units) do
      number_of_units * typical_electricity_production_per_unit
    end
  end
  attributes_required_for :production_based_on_number_of_units, [
    :number_of_units,
    :typical_electricity_production_per_unit
  ]

  def typical_electricity_production_capacity
    dataset_fetch_handle_nil(:typical_electricity_production_capacity) do
      electricity_output_conversion * typical_input_capacity
    end
  end
  attributes_required_for :typical_electricity_production_capacity, [
    :typical_input_capacity,
    :electricity_output_conversion
  ]

  def typical_electricity_production_per_unit
    dataset_fetch_handle_nil(:typical_electricity_production_per_unit) do
      typical_electricity_production_capacity * full_load_seconds
    end
  end
  attributes_required_for :typical_electricity_production_per_unit, [
    :typical_electricity_production_capacity,
    :full_load_seconds
  ]

  def installed_production_capacity_in_mw_electricity
    dataset_fetch_handle_nil(:installed_production_capacity_in_mw_electricity) do
      electricity_output_conversion * typical_nominal_input_capacity * number_of_units
    end
  end
  attributes_required_for :installed_production_capacity_in_mw_electricity, [
    :electricity_output_conversion,
    :typical_nominal_input_capacity,
    :number_of_units
  ]
  alias_method :electricity_production_in_mw, :installed_production_capacity_in_mw_electricity

  # The MW input capacity that is required to provide the demand.
  #
  # TODO:
  # 11.6.2012: issues with some scenarios (beta 28291), for some reason this method
  # returns nil. Temp fix to force-convert it to 0. CL+SB: please take a look at
  # this ASAP - PZ
  def mw_input_capacity
    out = dataset_fetch_handle_nil(:mw_input_capacity) do
      if full_load_seconds == 0.0
        0.0
      else
        demand / full_load_seconds
      end
    end
    out || 0.0 # FIXME!
  end
  attributes_required_for :mw_input_capacity, [:demand, :full_load_seconds]

  ##
  # Removed typical_production, refactored to typical_production
  # Added an alias untill the queries are altered
  #
  alias typical_production typical_electricity_production_per_unit

  ###instead of heat_production_in_mw, check for NIL in sum function!
  def installed_production_capacity_in_mw_heat
    return nil if required_attributes_contain_nil?(:installed_production_capacity_in_mw_heat)

    [
      useable_heat_output_conversion,
      steam_hot_water_output_conversion,
      hot_water_output_conversion
    ].compact.sum * typical_nominal_input_capacity * number_of_units
  end
  attributes_required_for :installed_production_capacity_in_mw_heat, [
    :typical_nominal_input_capacity,
    :number_of_units]
  alias_method :heat_production_in_mw, :installed_production_capacity_in_mw_heat

  # NOTE: disabled caching - Fri 29 Jul 2011 16:36:49 CEST
  #       - Fixed attributes_required_for and use handle_nil instead. SB - Thu 25. Aug 11
  def production_based_on_number_of_heat_units
    handle_nil(:production_based_on_number_of_heat_units) do
      number_of_units * typical_heat_production_per_unit
    end
  end
  attributes_required_for :production_based_on_number_of_heat_units, [
    :number_of_units,
    :typical_heat_production_per_unit
  ]

  def typical_heat_production_per_unit
    return nil if required_attributes_contain_nil?(:typical_heat_production_per_unit)
    [useable_heat_output_conversion,steam_hot_water_output_conversion,hot_water_output_conversion].
      compact.sum * typical_input_capacity * full_load_seconds
  end
  attributes_required_for :typical_heat_production_per_unit, [:typical_input_capacity]

end
