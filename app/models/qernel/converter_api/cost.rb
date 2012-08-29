# Supplies the Converter API with methods to calculate the yearly costs
# of a converter in a number of different units.
#
# Costs can be calculated in different units...
# * plant:           per typical size of a plant. This is
#                    the default unit, and is used internally
# * mw_input:        Costs per MW capacity of input fuel (MWinput)
# * mw_electricity:  Costs per MW electrical capacity (MWe)
#                    Used by costs scatter plot
# * mw_heat:         Costs per MW heat capacity (MWth)
# * converter:       How much do all the plants of a given type cost per year
#                    Used for total cost calculations for an area
# * mwh_input:       How much fuel is used as input for the plant in MWh
#                    Used for Merit Order charts.
# * mwh_electricity: How much electricity is produced by the plant per year
#                    in MWh. Used by the costs scatter plot.
# * mwh_heat:        How much heat is produced by the plant per year in MWh
# * full_load_hours  The costs per full load hour
#
# Calculation methods to go from plant/year to another unit:
# * plant:           DEFAULT unit, so no conversion needed
# * mw_input:        divide by method effective_input_capacity
# * mw_electricity:  divide by attribute output_capacity_electricity
# * mw_heat:         divide by attribute output_capacity_heat
# * converter:       multiply by number_of_units
# * mwh_input:       divide by (demand / SECS_PER_HOUR / number_of_units
# * mwh_electricity: divide by (output_of_electricity /
#                      SECS_PER_HOUR / number_of_units)
# * mwh_heat:        divide by (output_of_heat_carriers / SECS_PER_HOUR 
#                      / number_of_units)
# * full_load_hours  divide by full_load_hours



class Qernel::ConverterApi

  ##################
  # Input Capacity #
  ##################

  # Calculates the input capacity of a typical plant, based on
  # the output capacity in MW.
  # If the converter has an electrical efficiency this is used to calculate
  # the input capacity, otherwise it uses the heat capacity
  #
  # @param []
  #
  # @return [Float] Input capacity of a typical plant
  #
  def nominal_input_capacity
    function(:nominal_input_capacity) do
      electric_based_nominal_input_capacity ||
        heat_based_nominal_input_capacity || 0.0
    end
  end

  # Calculates the effective input capacity of a plant (in MW) based on the
  # nominal input capacity and the average effective capacity over
  # the lifetime of a plant.
  #
  # Assumes a value of 100% when
  # average_effective_output_of_nominal_capacity_over_lifetime is not set
  #
  # @param []
  #
  # @return [Float] Effective input capacity of a typical plant in MW
  #
  def effective_input_capacity
    function(:effective_input_capacity) do
      if average_effective_output_of_nominal_capacity_over_lifetime
        nominal_input_capacity * 
          average_effective_output_of_nominal_capacity_over_lifetime
      else
        nominal_input_capacity
      end
    end
  end

  ##########################
  # Total Cost calculation #
  ##########################

  # Calculates the total cost of a converter in a given unit.
  # Total cost is made up of fixed costs and variable costs.
  #
  # In GQL use total_cost_per_unit (where unit is the unit parameter)
  #
  # @return [Float] total costs for one unit or plant
  #
  def total_costs
    function(:total_costs) do
      fixed_costs + variable_costs
    end
  end


  ###############
  # Fixed Costs #
  ###############

  # Calculates the fixed costs of a converter in a given unit.
  # Fixed costs are made up of cost of capital, depreciation costs
  # and fixed operation and maintenance costs.
  #
  # @return [Float]
  #
  def fixed_costs
    function(:fixed_costs) do
      cost_of_capital + depreciation_costs +
        fixed_operation_and_maintenance_costs
    end
  end

  # Calculates the yearly costs of capital for the unit, based on the average
  # yearly payment, the weighted average cost of capital (WACC) and a factor
  # to include the construction time in the total rent period of the loan.
  # ETM assumes that capital has to be held during construction time
  # (and so interest has to be paid during this period) and that technical
  # and economic lifetime are the same.
  #
  # Used in the calculation of fixed costs
  #
  # @param []
  #
  # @return [Float]
  #
  def cost_of_capital
    function(:cost_of_capital) do
      average_investment_costs * wacc *
        (construction_time + technical_lifetime) /
          technical_lifetime
    end
  end

  # Determines the yearly depreciation of the plant over its lifetime.
  # The straight-line depreciation methodology is used.
  #
  # Used to determine fixed costs
  #
  # @return [Float]
  #
  def depreciation_costs
    function(:depreciation_costs) do
      (total_investment_costs - residual_value) / technical_lifetime
    end
  end


  ##################
  # Variable Costs #
  ##################

  # Calculates the variable costs in a given unit. Defaults to plant.
  # The variable costs cannot be calculated without knowing how much
  # fuel is consumed by the plant, how much this (mix of) fuel costs
  # etc. The logic is therefore more complex than the fixed costs.
  #
  # Variable costs are made up of fuel costs, co2 emission credit costs
  # and variable operation and mainentance costs
  #
  # @return [Float]
  #
  def variable_costs
    function(:variable_costs) do
      fuel_costs + co2_emissions_costs +
        variable_operation_and_maintenance_costs
    end
  end

  # Calculates the fuel costs for a single plant, based on the input of fuel
  # for one plant, the
  #
  def fuel_costs
    function(:fuel_costs) do
      typical_fuel_input * weighted_carrier_cost_per_mj
    end
  end

  # DEBT: rename co2_free and part_ets
  # DEBT: move factors to a separate function ?
  #
  # input of fuel in mj * the amount of co2 per mj * the co2 price * how much
  # co2 is given away for free * how much of the co2 of this plant is in ETS
  # * how much co2 is not counted (non-energetic or CCS plants) / the number
  # of units
  #
  def co2_emissions_costs
    function(:co2_emissions_costs) do
      typical_fuel_input * weighted_carrier_co2_per_mj * area.co2_price *
        (1 - area.co2_percentage_free) * part_ets * ((1 - co2_free))
    end
  end

  def variable_operation_and_maintenance_costs
    function(:variable_operation_and_maintenance_costs) do
      full_load_hours * (
        variable_operation_and_maintenance_costs_per_full_load_hour +
        variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour )
    end
  end


  ###################
  # Chart functions #
  ###################

  # Calculates the inital investment costs of a plant, based on the
  # initial investment (purchase costs), installation costs and
  # the additional cost for CCS (if applicable)
  #
  # Used in the scatter plot for costs
  #
  # DEBT: should not be named _costs, since it it an expenditure, not a cost!
  #       option: total_initial_investment
  #
  def initial_investment_costs
    function(:initial_investment_costs) do
      initial_investment + ccs_investment + cost_of_installing
    end
  end


  #########
  private
  #########

  # The average yearly installment of capital cost repayments, assuming
  # a linear repayment scheme. That is why divided by 2, to be at 50% between
  # initial cost and 0.
  #
  # DEBT: decomissioning costs should be paid at the end of lifetime,
  # and so should not have a WACC associated with it.
  #
  # Used to determine cost of capital
  #
  def average_investment_costs
    function(:average_investment_costs) do
      (initial_investment_costs + decommissioning_costs) / 2
    end
  end

  # Used to calculate yearly depreciation costs
  #
  # DEBT: this function should be used for investment costs in the scatter
  #   plot of the ETM as well.
  # DEBT: should be named total_investments (without costs)
  def total_investment_costs
    function(:total_investment_costs) do
      initial_investment_costs + decommissioning_costs
    end
  end

  # Used for calculating the nominal_input_capacity
  def electric_based_nominal_input_capacity
    function(:electric_based_nominal_input_capacity) do
      electricity_output_capacity / electricity_output_conversion rescue nil
    end
  end

  def heat_based_nominal_input_capacity
    function(:heat_based_nominal_input_capacity) do
      heat_output_capacity / heat_output_conversion rescue nil
    end
  end
  
  # Calculates the typical fuel input of one plant of this type
  #
  # Used for variable costs: fuel costs and CO2 emissions costs
  #
  # @return [Float] Typical fuel input in MJ
  #
  def typical_fuel_input
    function(:typical_fuel_input) do
      effective_input_capacity * full_load_seconds
    end
  end

end
