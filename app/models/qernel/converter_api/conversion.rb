class Qernel::ConverterApi

  # For the following attributes and methods we want to have a method that
  # returns the cost for a given unit.
  #
  # Example:
  #   total_costs_per(:converter)
  #   => 129721.8
  #
  # @param [symbol] The unit to convert the cost parameter in.
  # Allowed: :plant, :converter, :mw_input, :mw_electricity,
  # :mw_heat, :mwh_input, :mwh_electricity, :mwh_heat,
  # :full_load_hour
  #
  # @return [Float] the Cost per plant converted to Cost per unit as
  # specified in the parameter
  #
  
  # CONVERTER ATTRIBUTES TO CONVERT
  def initial_investment_per(unit)
    convert_to initial_investment, unit
  end
  
  def ccs_investment_per(unit)
    convert_to ccs_investment, unit
  end
  
  def cost_of_installing_per(unit)
    convert_to cost_of_installing, unit
  end
  
  def fixed_operation_and_maintenance_costs_per(unit)
    convert_to fixed_operation_and_maintenance_costs_per_year, unit
  end
  
  def decommissioning_costs_per(unit)
    convert_to decommissioning_costs, unit
  end
  
  def residual_value_per(unit)
    convert_to residual_value, unit
  end
  
  # CONVERTER METHODS TO CONVERT
  def total_costs_per(unit)
    convert_to total_costs, unit
  end

  def fixed_costs_per(unit)
    convert_to fixed_costs, unit
  end

  def depreciation_costs_per(unit)
    convert_to depreciation_costs, unit
  end

  def cost_of_capital_per(unit)
    convert_to cost_of_capital, unit
  end

  def variable_costs_per(unit)
    convert_to variable_costs, unit
  end

  def fuel_costs_per(unit)
    convert_to fuel_costs, unit
  end

  def co2_emissions_costs_per(unit)
    convert_to co2_emissions_costs, unit
  end

  def variable_operation_and_maintenance_costs_per(unit)
    convert_to variable_operation_and_maintenance_costs, unit
  end

  def initial_investment_costs_per(unit)
    convert_to initial_investment_costs, unit
  end

  #######
  private
  #######

  # This methods converts the cost of one (typical sized) 'plant'
  # to another unit.
  #
  # Example:
  #   convert_to(1000, :mw_input)
  #   => 1272.16
  #
  # Of course, you can use the outcome of another method here:
  #
  # Example:
  #   convert_to(total_costs, :mw_input)
  #   => 12972.12
  #
  # @param [Float] The cost in euro / plant / year to be converted
  # to another unit
  #
  # @param [symbol] The unit to convert the cost parameter in.
  # Allowed: :plant, :converter, :mw_input, :mw_electricity,
  # :mw_heat, :mwh_input, :mwh_electricity, :mwh_heat,
  # :full_load_hour
  #
  # @return [Float] Cost converted to Cost per Unit
  #
  def convert_to(cost, unit)
    case unit

    # Plant and Converter
    when :plant
      cost
    when :converter
      cost * number_of_units

    # MW capacity
    when :mw_input
      cost / effective_input_capacity
    when :mw_electricity
      cost / electricity_output_capacity
    when :mw_heat
      cost / heat_output_capacity

    # MWh production
    when :mwh_input
      cost / typical_fuel_input * SECS_PER_HOUR
    when :mwh_electricity
      cost / typical_electricity_output * SECS_PER_HOUR
    when :mwh_heat
      cost / typical_heat_output * SECS_PER_HOUR

    # full load hours
    when :full_load_hour
      cost / full_load_hours

    # Some other unit that is unknown
    else
      raise ArgumentError, "#{unit} unknown! Cannot convert."
    end
  end

end
