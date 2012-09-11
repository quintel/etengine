class Qernel::ConverterApi

  # The required installed input capacity, based on the demand.
  def mwh_input
    function(:mwh_input) do
      demand / SECS_PER_HOUR
    end
  end

  # The output of electricity expressed in MWh.
  def mwh_electricy_output
    function(:mwh_electricy_output) do
      output_of_electricity / SECS_PER_HOUR
    end
  end

  # Determines the average typical input capacity over its lifetime, accounting for the loss in nominal capacity over its lifetime.
  #
  def typical_input_capacity_in_mw
    function(:typical_input_capacity_in_mw) do
      typical_nominal_input_capacity * average_effective_output_of_nominal_capacity_over_lifetime
    end
  end
  # TODO: get rid of the alias
  alias typical_input_capacity typical_input_capacity_in_mw

  ## Returns the nominal electrical capicity of one unit.
  #
  def nominal_capacity_electricity_output_per_unit
    function(:nominal_capacity_electricity_output_per_unit) do
      typical_nominal_input_capacity * electricity_output_conversion
    end
  end

  ## Returns the nominal heat capicity of one unit. This is both useable heat as steam_hot_water.
  #
  def nominal_capacity_heat_output_per_unit
    function(:nominal_capacity_heat_output_per_unit) do
      typical_nominal_input_capacity * heat_output_conversion
    end
  end

  ## Returns the nominal cooling capacity of one unit
  #
  def nominal_capacity_cooling_output_per_unit
    function(:nominal_capacity_cooling_output_per_unit) do
      typical_nominal_input_capacity * cooling_output_conversion
    end
  end
  
  ## Returns the total heat output conversion of one unit. This is useable heat and steam_hot_water.
  #
  def heat_output_conversion
    function(:heat_output_conversion) do
      (steam_hot_water_output_conversion  + useable_heat_output_conversion)
    end
  end
  
  ## Returns the total heat and cold output conversion of one unit. This is useable heat, steam_hot_water and cooling.
  #
  def heat_and_cold_output_conversion
    function(:heat_and_cold_output_conversion) do
      (steam_hot_water_output_conversion + useable_heat_output_conversion + cooling_output_conversion)
    end
  end

  def coefficient_of_performance
    function(:coefficient_of_performance) do
      (1 / (1 - ( ambient_heat_input_conversion + ambient_cold_input_conversion + geothermal_input_conversion)))
    end
  end
  
  # How many seconds a year the converters runs at full load.
  # This is useful because MJ is MW per second.
  def full_load_seconds
    function(:full_load_seconds) do
      full_load_hours * SECS_PER_HOUR
    end
  end
  
  def production_based_on_number_of_units
    function(:production_based_on_number_of_units) do
      number_of_units * typical_electricity_production_per_unit
    end
  end
  
  def typical_electricity_production_capacity
    function(:typical_electricity_production_capacity) do
      electricity_output_conversion * typical_input_capacity
    end
  end
  
  def typical_electricity_production_per_unit
    function(:typical_electricity_production_per_unit) do
      typical_electricity_production_capacity * full_load_seconds
    end
  end
  
  # Removed typical_production, refactored to typical_production
  # Added an alias untill the queries are altered
  #
  # DEBT: not used:
  alias typical_production typical_electricity_production_per_unit

  def installed_production_capacity_in_mw_electricity
    function(:installed_production_capacity_in_mw_electricity) do
      electricity_output_conversion * typical_nominal_input_capacity * number_of_units
    end
  end
  alias_method :electricity_production_in_mw, :installed_production_capacity_in_mw_electricity

  # The MW power that is consumed by an electricity consuming technology.
  #
  # TODO:
  # 11.6.2012: issues with some scenarios (beta 28291), for some reason this method
  # returns nil. Temp fix to force-convert it to 0. CL+SB: please take a look at
  # this ASAP - PZ
  def mw_power
    out = function(:mw_power) do
      if full_load_seconds == 0.0
        0.0
      else
        demand / full_load_seconds
      end
    end
    out || 0.0 # FIXME!
  end

  # The MW input capacity of a (electricity producing) technology
  # NOTE: this function is identical to mw_power (defined above)
  # power is a more precise name if we talk about the actually consumed MWs
  # capacity is the maximal power and therefore more appropriate to calculate
  # the output of electricity generating technologies.
  alias_method :mw_input_capacity, :mw_power

  ###instead of heat_production_in_mw, check for NIL in sum function!
  def installed_production_capacity_in_mw_heat
    return nil if [typical_nominal_input_capacity, number_of_units].any?(&:nil?)
    [
      useable_heat_output_conversion,
      steam_hot_water_output_conversion
    ].compact.sum * typical_nominal_input_capacity * number_of_units
  end
  alias_method :heat_production_in_mw, :installed_production_capacity_in_mw_heat

  # NOTE: disabled caching - Fri 29 Jul 2011 16:36:49 CEST
  #       - Fixed attributes_required_for and use handle_nil instead. SB - Thu 25. Aug 11
  def production_based_on_number_of_heat_units
    return nil if [number_of_units, typical_heat_production_per_unit].any?(&:nil?)
    number_of_units * typical_heat_production_per_unit
  end
  
  def typical_heat_production_per_unit
    return nil if typical_input_capacity.nil?
    [
      useable_heat_output_conversion, 
      steam_hot_water_output_conversion
    ].compact.sum * typical_input_capacity * full_load_seconds
  end
end
