class Qernel::NodeApi

  # For the following attributes and methods we want to have a method that
  # returns the cost for a given unit.
  #
  # Example:
  #   total_costs_per(:node)
  #   => 129721.8
  #
  # @param [symbol] The unit to convert the cost parameter in.
  # Allowed: :plant, :node, :mw_input, :mw_electricity,
  # :mw_heat, :mwh_input, :mwh_electricity, :mwh_heat,
  # :full_load_hour
  #
  # Costs can be calculated in different units...
  # * plant:           per typical size of a plant.
  # * mw_input:        Costs per MW capacity of input fuel (MWinput)
  # * mw_electricity:  Costs per MW electrical capacity (MWe)
  #                    Used by costs scatter plot
  # * mw_heat:         Costs per MW heat capacity (MWth)
  # * node:            How much do all the plants of a given type cost per year
  #                    Used for total cost calculations for an area.
  #                    Aliased as :node.
  # * mwh_input:       What are the costs per MWh of fuel input
  # * mwh_electricity: what are the costs per MWh of electricity the plant produces
  #                    Used by the costs scatter plot.
  # * mwh_heat:        what are the costs per MWh of heat the plant produces
  # * full_load_hour  The costs per full load hour
  #
  # Calculation methods to go from plant/year to another unit:
  # * plant:           DEFAULT unit, so no conversion needed
  # * mw_input:        divide by method input_capacity
  # * mw_electricity:  divide by attribute electricity_output_capacity
  # * mw_heat:         divide by attribute heat_output_capacity
  # * node:            multiply by number_of_units, aliased as :node
  # * mwh_input:       divide by private method typical_input then
  #                    multiply by SECS_PER_HOUR
  # * mwh_electricity: divide by private method typical_electricity_output then
  #                    multiply by SECS_PER_HOUR
  # * mwh_heat:        divide by private method typical_heat_output then
  #                    multiply by SECS_PER_HOUR
  # * full_load_hours  divide by full_load_hours
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

  def merit_order_variable_costs_per(unit)
    convert_to merit_order_variable_costs, unit
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

  def total_initial_investment_per(unit)
    convert_to total_initial_investment, unit
  end

  def total_investment_over_lifetime_per(unit)
    convert_to total_investment_over_lifetime, unit
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
  # Allowed: :plant, :node, :mw_input, :mw_electricity,
  # :mw_heat, :mwh_input, :mwh_electricity, :mwh_heat,
  # :full_load_hour
  #
  # @return [Float] Cost converted to Cost per Unit
  #
  def convert_to(cost, unit)
    value = case unit

    # Plant and Node
    when :plant
      cost
    when :node, :node
      cost * number_of_units

    # MW capacity
    when :mw_input
      cost / input_capacity.to_f
    when :mw_typical_input_capacity
      cost / typical_input_capacity.to_f
    when :mw_electricity
      cost / electricity_output_capacity.to_f
    when :mw_heat
      cost / heat_output_capacity.to_f

    # MWh production
    when :mwh_input
      cost / typical_input.to_f * SECS_PER_HOUR
    when :mwh_electricity
      cost / typical_electricity_output.to_f * SECS_PER_HOUR
    when :mwh_heat
      cost / typical_heat_output.to_f * SECS_PER_HOUR

    # full load hours
    when :full_load_hour
      cost / full_load_hours.to_f

    # Some other unit that is unknown
    else
      raise ArgumentError, "#{unit} unknown! Cannot convert."
    end

    (value && value.to_f == Float::INFINITY) ? 0.0 : value
  end

end
