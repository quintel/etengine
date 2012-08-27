class Qernel::ConverterApi

  # For the following methods we want to have a method that
  # returns the cost per unit.
  #
  # Example:
  #   total_costs_per(:converter)
  #   => 129721.8
  #
  def total_costs_per(unit)
    convert_to total_costs, unit
  end

  def fixed_costs_per(unit)
    convert_to fixed_costs, unit
  end

  def depreciation_costs_per(unit)
    convert_to depreciation_costs, unit
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

  def variable_operations_and_maintenance_costs_per(unit)
    convert_to variable_operations_and_maintenance_costs, unit
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
  def convert_to(cost, unit)
    case unit

    # Plant and Converter
    when :plant
      cost
    when :converter
      cost * real_number_of_units

    # MW
    when :mw_input
      cost / effective_input_capacity
    when :mw_electricity
      cost / output_capacity_electricity
    when :mw_heat
      cost / output_capacity_heat

    # MWh
    when :mwh_input
      cost / demand / SECS_PER_HOUR / real_number_of_units
    when :mwh_electricity
      cost / output_of_electricity / SECS_PER_HOUR / real_number_of_units
    when :mwh_heat
      cost / output_of_heat_carriers / SECS_PER_HOUR / real_number_of_units

    # Some other unit that is unknown
    else
      raise ArgumentError, "#{unit} unknown! Cannot convert."
    end
  end

end
