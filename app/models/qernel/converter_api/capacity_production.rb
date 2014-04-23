class Qernel::ConverterApi
# DEBT: Clean up this file! wmeyers - 20120830

  # The required installed input capacity, based on the demand.
  def mwh_input
    fetch(:mwh_input) { demand / SECS_PER_HOUR }
  end
  unit_for_calculation "mwh_input", 'MWh'

  ## Returns the nominal electrical capicity of one unit.
  #
  def nominal_capacity_electricity_output_per_unit
    fetch(:nominal_capacity_electricity_output_per_unit) do
      input_capacity * electricity_output_conversion
    end
  end
  unit_for_calculation "nominal_capacity_electricity_output_per_unit", 'MW'

  ## Returns the nominal heat capicity of one unit. This is both useable heat as steam_hot_water.
  #
  def nominal_capacity_heat_output_per_unit
    fetch(:nominal_capacity_heat_output_per_unit) do
      input_capacity * heat_output_conversion
    end
  end
  unit_for_calculation "nominal_capacity_heat_output_per_unit", 'MW'

  ## Returns the nominal cooling capacity of one unit
  #
  def nominal_capacity_cooling_output_per_unit
    fetch(:nominal_capacity_cooling_output_per_unit) do
      input_capacity * cooling_output_conversion
    end
  end
  unit_for_calculation "nominal_capacity_cooling_output_per_unit", 'MW'

  ## Returns the total heat output conversion of one unit. This is useable heat and steam_hot_water.
  #
  def heat_output_conversion
    fetch(:heat_output_conversion) do
      (steam_hot_water_output_conversion  + useable_heat_output_conversion)
    end
  end
  unit_for_calculation "heat_output_conversion", 'factor'

  ## Returns the total heat and cold output conversion of one unit. This is useable heat, steam_hot_water and cooling.
  #
  def heat_and_cold_output_conversion
    fetch(:heat_and_cold_output_conversion) do
      (steam_hot_water_output_conversion + useable_heat_output_conversion + cooling_output_conversion)
    end
  end
  unit_for_calculation "heat_and_cold_output_conversion", 'factor'

  def coefficient_of_performance
    fetch(:coefficient_of_performance) do
      (1 / (1 - ( ambient_heat_input_conversion + ambient_cold_input_conversion + geothermal_input_conversion)))
    end
  end
  unit_for_calculation "coefficient_of_performance", ''

  # How many seconds a year the converters runs at full load.
  # This is useful because MJ is MW per second.
  def full_load_seconds
    fetch(:full_load_seconds) { full_load_hours * SECS_PER_HOUR }
  end
  unit_for_calculation "full_load_seconds", 'seconds'

  def production_based_on_number_of_units
    fetch(:production_based_on_number_of_units) do
      number_of_units * typical_electricity_production_per_unit
    end
  end
  unit_for_calculation "production_based_on_number_of_units", 'MJ'

  def typical_electricity_production_capacity
    fetch(:typical_electricity_production_capacity) do
      electricity_output_conversion * input_capacity
    end
  end
  unit_for_calculation "typical_electricity_production_capacity", 'MW'

  def typical_electricity_production_per_unit
    fetch(:typical_electricity_production_per_unit) do
      typical_electricity_production_capacity * full_load_seconds
    end
  end
  unit_for_calculation "typical_electricity_production_per_unit", 'MJ'

  def installed_production_capacity_in_mw_electricity
    fetch(:installed_production_capacity_in_mw_electricity) do
      electricity_output_conversion * input_capacity * number_of_units
    end
  end
  unit_for_calculation "installed_production_capacity_in_mw_electricity", 'MW'
  alias_method :electricity_production_in_mw, :installed_production_capacity_in_mw_electricity

  # The MW power that is consumed by an electricity consuming technology.
  #
  # TODO:
  # 11.6.2012: issues with some scenarios (beta 28291), for some reason this method
  # returns nil. Temp fix to force-convert it to 0. CL+SB: please take a look at
  # this ASAP - PZ
  def mw_power
    fetch(:mw_power) do
      full_load_seconds == 0.0 ? 0.0 : demand / full_load_seconds
    end
  end
  unit_for_calculation "mw_power", 'MW'

  # The MW input capacity of a (electricity producing) technology
  # NOTE: this function is identical to mw_power (defined above)
  # power is a more precise name if we talk about the actually consumed MWs
  # capacity is the maximal power and therefore more appropriate to calculate
  # the output of electricity generating technologies.
  alias_method :mw_input_capacity, :mw_power
  unit_for_calculation "mw_input_capacity", 'MW'

  # Heat

  ###instead of heat_production_in_mw, check for NIL in sum function!
  def installed_production_capacity_in_mw_heat
    if input_capacity && number_of_units
      heat_output_conversion * input_capacity * number_of_units
    end
  end
  unit_for_calculation "installed_production_capacity_in_mw_heat", 'MW'
  alias_method :heat_production_in_mw, :installed_production_capacity_in_mw_heat

  # NOTE: disabled caching - Fri 29 Jul 2011 16:36:49 CEST
  #       - Fixed attributes_required_for and use handle_nil instead. SB - Thu 25. Aug 11
  def production_based_on_number_of_heat_units
    if number_of_units && typical_heat_production_per_unit
      number_of_units * typical_heat_production_per_unit
    end
  end
  unit_for_calculation "production_based_on_number_of_heat_units", 'MJ'

  def typical_heat_production_per_unit
    if input_capacity
      heat_output_conversion * input_capacity * full_load_seconds
    end
  end
  unit_for_calculation "typical_heat_production_per_unit", 'MJ'

end
