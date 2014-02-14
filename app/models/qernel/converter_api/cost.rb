  # Supplies the Converter API with methods to calculate the yearly costs
  # of one plant.
  #
  # These methods are used in conversion.rb to offer a possibility to convert
  # to a number of different units.
  #

class Qernel::ConverterApi

  ##################
  # Input Capacity #
  ##################

  # Calculates the input capacity of a typical plant, based on the output
  # capacity in MW.
  #
  # If the converter has an electrical efficiency and capacity this is used to
  # calculate the input capacity. Otherwise it checks for a heat capacity and
  # heat efficiency. If this can also not be found it will try cooling.
  #
  # Finally it will try the attribute typical_input_capacity (currently only
  # used for electric transport). If all return nil 0.0 will be used. This
  # should only happen for statistical converters.
  #
  # @return [Float] Input capacity of a typical plant in MWinput
  #
  # DEBT: move to another file when cleaning up Converter API
  def input_capacity
    fetch(:input_capacity) do
      electric_based_input_capacity ||
        heat_based_input_capacity ||
        cooling_based_input_capacity ||
        typical_input_capacity || 0.0
    end
  end
  unit_for_calculation "input_capacity", 'MWinput'

  ###################
  # Chart functions #
  ###################

  # Calculates the inital investment costs of a plant, based on the
  # initial investment (purchase costs), installation costs and
  # the additional cost for CCS (if applicable)
  #
  # Used in the scatter plot for costs
  #
  def total_initial_investment
    fetch(:total_initial_investment) do
      initial_investment + ccs_investment + cost_of_installing
    end
  end
  unit_for_calculation "total_initial_investment", 'euro / plant'

  # The total investment required at the beginning of the project
  # plus the decommissioning costs which have to be paid at the end
  # of the project.
  #
  # Note that decommissioning costs have capital costs associated with
  # them, because it is assumed that the money for this has to be
  # paid up front. This is also the case in the Netherlands.
  #
  # Used to calculate yearly depreciation costs
  #
  #
  def total_investment_over_lifetime
    fetch(:total_investment_over_lifetime) do
      total_initial_investment + decommissioning_costs
    end
  end
  unit_for_calculation "total_investment_over_lifetime", 'euro / plant'

  #########
  private
  #########

  ##########################
  # Total Cost calculation #
  ##########################

  # Calculates the total cost of a plant in euro per plant per year.
  # Total cost is made up of fixed costs and variable costs.
  #
  # @return [Float] total costs for one plant
  #
  def total_costs
    fetch(:total_costs) do
      if fixed_costs && variable_costs
        fixed_costs + variable_costs
      end
    end
  end
  unit_for_calculation "total_costs", 'euro / plant / year'

  ###############
  # Fixed Costs #
  ###############

  # Calculates the fixed costs of a converter in a given unit.
  # Fixed costs are made up of cost of capital, depreciation costs
  # and fixed operation and maintenance costs.
  #
  # Note that fixed_operation_and_maintenance_costs_per_year is
  # an attribute of the Converter. There is therefore no method
  # to 'calculate' this for one plant. In conversion.rb there is
  # a method to convert to different other cost units however.
  #
  # @return [Float] total fixed costs for one plant
  #
  def fixed_costs
    fetch(:fixed_costs) do
      cost_of_capital + depreciation_costs +
        fixed_operation_and_maintenance_costs_per_year
    end
  end
  unit_for_calculation "fixed_costs", 'euro / plant / year'

  # Calculates the yearly costs of capital for the unit, based on the average
  # yearly payment, the weighted average cost of capital (WACC) and a factor
  # to include the construction time in the total rent period of the loan.
  # The ETM assumes that capital has to be held during construction time
  # (and so interest has to be paid during this period) and that technical
  # and economic lifetime are the same.
  #
  # Used in the calculation of fixed costs
  #
  # @return [Float] yearly cost of capital for one plant
  #
  def cost_of_capital
    fetch(:cost_of_capital) do
      average_investment * wacc *
        (construction_time + technical_lifetime) /
          technical_lifetime
    end
  end
  unit_for_calculation "cost_of_capital", 'euro / plant / year'

  # Determines the yearly depreciation of the plant over its lifetime.
  # The straight-line depreciation methodology is used.
  #
  # Used to determine fixed costs
  #
  # @return [Float] yearly depreciation costs of the plant using the
  # straight-line depreciation method
  #
  def depreciation_costs
    fetch(:depreciation_costs) do
      total_investment_over_lifetime / technical_lifetime
    end
  end
  unit_for_calculation "depreciation_costs", 'euro / plant / year'

  ##################
  # Marginal Costs #
  ##################

  # Calculates the marginal costs for a plant in euro per MWh produced
  # electricity. This is the same as the variable costs per typical input 
  # divided through electricity_output_conversion (times SECS_PER_HOUR to 
  # convert from euro / MJ to euro / MWh).
  # The marginal costs are the **extra** costs made if an **extra** unit
  # of electricity is produced. It is, in essence, the slope of the cost 
  # curve where cost (in euro) is plotted versus total production (in MWh).
  #
  # @return [Float] marginal costs per MWh (produced electricity)
  #
  def marginal_costs
    variable_costs_per_typical_input * 
    SECS_PER_HOUR / electricity_output_conversion
  end
  unit_for_calculation "marginal_costs", 'euro / MWh'

  ##################
  # Variable Costs #
  ##################

  # Calculates the variable costs for one plant.
  # The variable costs cannot be calculated without knowing how much
  # fuel is consumed by the plant, how much this (mix of) fuel costs
  # etc. The logic is therefore more complex than the fixed costs.
  #
  # Variable costs are made up of fuel costs, co2 emission credit costs
  # and variable operation and mainentance costs
  #
  # @return [Float] the total variable costs of one plant
  #
  def variable_costs
    fetch(:variable_costs) { typical_input * variable_costs_per_typical_input }
  end
  unit_for_calculation "variable_costs", 'euro / plant / year'

  # Calculates the variable costs per typical input (in MJ). 
  # Unlike the variable_costs (defined above), this function does not
  # explicity depend on the production of the plant.
  #
  # @return [Float] 
  def variable_costs_per_typical_input
    fetch(:variable_costs_per_typical_input) do
      (weighted_carrier_cost_per_mj + 
       co2_emissions_costs_per_typical_input +
       variable_operation_and_maintenance_costs_per_typical_input)
    end
  end
  unit_for_calculation "variable_costs_per_typical_input", 'euro / MJ'

  # Calculates the fuel costs for a single plant, based on the input of fuel
  # for one plant and the weighted costs of this/these carrier(s) per mj.
  #
  # @return [Float] the yearly fuel costs for one single plant
  #
  def fuel_costs
    fetch(:fuel_costs) {typical_input * weighted_carrier_cost_per_mj }
  end
  unit_for_calculation "fuel_costs", 'euro / plant / year'

  # This method determines the costs of co2 emissions by doing:
  # Typical input of fuel in mj * the amount of co2 per mj fuel *
  # the co2 price * how much co2 is given away for free *
  # Is this converter part of the ETS? *
  # how much co2 is not counted (non-energetic or CCS plants)
  #
  #
  # @return [Float] the yearly costs for co2 emissions for one plant
  #
  def co2_emissions_costs
    fetch(:co2_emissions_costs) do
      typical_input * co2_emissions_costs_per_typical_input
    end
  end
  unit_for_calculation "co2_emissions_costs", 'euro / plant / year'

  # Calculates the CO2 emission costs per typical input (in MJ). 
  # Unlike the co2_emissions_costs (defined above), this function does not
  # explicity depend on the production of the plant.
  #
  # DEBT: rename free_co2_factor and takes_part_in_ets
  #
  # @return [Float] 
  def co2_emissions_costs_per_typical_input
    fetch(:co2_emissions_costs_per_typical_input) do
      weighted_carrier_co2_per_mj * area.co2_price *
      (1 - area.co2_percentage_free) * takes_part_in_ets * ((1 - free_co2_factor)) 
    end
  end
  unit_for_calculation "co2_emissions_costs_per_typical_input", 'euro / MJ'

  # Calculates the variable operation and maintenance costs for one plant.
  # These costs are made up of variable O&M costs for the plant per full load
  # hour and the variable O&M costs for CCS for this plant. Most plants have
  # a variable O&M costs component, but only CCS plants have CCS O&M costs.
  #
  # @return [Float] Yearly variable operation and maintenance costs per plant
  #
  def variable_operation_and_maintenance_costs
    fetch(:variable_operation_and_maintenance_costs) do
      typical_input *
      variable_operation_and_maintenance_costs_per_typical_input
    end
  end
  unit_for_calculation "variable_operation_and_maintenance_costs", 'euro / plant / year'

  # Calculates the variable_operation_and_maintenance_costs per typical input 
  # (in MJ).
  # Unlike the variable_operation_and_maintenance_costs (defined above), this 
  # function does not explicity depend on the production of the plant.
  #
  # @return [Float] Yearly variable operation and maintenance costs per typical 
  # input
  #
  def variable_operation_and_maintenance_costs_per_typical_input
    fetch(:variable_operation_and_maintenance_costs_per_typical_input) do
      (variable_operation_and_maintenance_costs_per_full_load_hour +
      variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour) /
      (input_capacity * 3600.0)
    end
  end
  unit_for_calculation "variable_operation_and_maintenance_costs_per_typical_input", 'euro / MJ'

  # The average yearly installment of capital cost repayments, assuming
  # a linear repayment scheme. That is why divided by 2, to be at 50% between
  # initial cost and 0.
  #
  # Used to determine cost of capital
  #
  def average_investment
    fetch(:average_investment) { (total_investment_over_lifetime) / 2 }
  end
  unit_for_calculation "average_investment", 'euro / plant / year'

  # This method calculates the input capacity of a plant based on the
  # electrical output capacity and electrical efficiency of the converter
  #
  # @return [Float] the typical input capacity of a plant in MWinput
  #
  # DEBT: move to another file when cleaning up Converter API
  #
  def electric_based_input_capacity
    fetch(:electric_based_input_capacity) do
      if electricity_output_conversion && electricity_output_conversion > 0
        electricity_output_capacity / electricity_output_conversion
      end
    end
  end
  unit_for_calculation "electric_based_input_capacity", 'MWinput'

  # This method calculates the input capacity of a plant based on the
  # heat output capacity and heat efficiency of the converter
  #
  # @return [Float] the typical input capacity of a plant in MWinput
  #
  # DEBT: move to another file when cleaning up Converter API
  #
  def heat_based_input_capacity
    fetch(:heat_based_input_capacity) do
      if heat_output_conversion && heat_output_conversion > 0
        heat_output_capacity / heat_output_conversion
      end
    end
  end
  unit_for_calculation "heat_based_input_capacity", 'MWinput'

  # This method calculates the input capacity of one plant based on the
  # heat capacity of the plant and the cooling efficiency.
  #
  # The ETM does not have seperate cooling capacity, so use heat capacity to
  # calculate cooling based nominal input capacity. This method will only
  # be called with cooling technologies which have no heat output.
  #
  # @return [Float] the input capacity of a plant based on the output
  # capacity and the cooling efficiency of the plant
  #
  # DEBT: move to another file when cleaning up Converter API
  #
  def cooling_based_input_capacity
    fetch(:cooling_based_input_capacity) do
      if cooling_output_conversion && cooling_output_conversion > 0
        heat_output_capacity / cooling_output_conversion
      end
    end
  end
  unit_for_calculation "cooling_based_input_capacity", 'MWinput'

  # Calculates the typical electricity output of one plant of this type
  #
  # Used for conversion of plant to other units
  #
  # @return [Float] Typical electricity output in MJ
  #
  # DEBT: move to another file when cleaning up Converter API
  #
  def typical_electricity_output
    fetch(:typical_electricity_output) do
      typical_input * electricity_output_conversion
    end
  end
  unit_for_calculation "typical_electricity_output", 'MJ / year'

  # Calculates the typical heat output of one plant of this type
  #
  # Used for conversion of plant to other units
  #
  # @return [Float] Typical heat output in MJ
  #
  # DEBT: move to another file when cleaning up Converter API
  #
  def typical_heat_output
    fetch(:typical_heat_output) do
      typical_input * heat_and_cold_output_conversion
    end
  end
  unit_for_calculation "typical_heat_output", 'MJ / year'

  # Calculates the typical fuel input of one plant of this type
  #
  # Used for variable costs: fuel costs and CO2 emissions costs
  #
  # @return [Float] Typical fuel input of one plant in MJ
  #
  # DEBT: move to another file when cleaning up Converter API
  #
  def typical_input
    fetch(:typical_input) { input_capacity * full_load_seconds }
  end
  unit_for_calculation "typical_input", 'MJ / year'
end
