# Supplies the Converter API with methods to calculate the yearly costs
# of a converter in a number of different units
# 
# 
# Costs can be calculated in different units...

class Qernel::ConverterApi

  #############################
  # Calculate Input Capacity #
  ############################

  # Calculates the input capacity of a typical plant, based on
  # the output capacity in MW. 
  # If the converter has an electrical efficiency this is used to calculate
  # the input capacity, otherwise it uses the heat capacity
  #
  # @param []
  #   
  # 
  # @return [Float] Input capacity of a typical plant
  #
  def nominal_input_capacity
     function(:nominal_input_capacity) do
       if electricity_output_conversion > 0.0
         output_capacity_electricity / electricity_output_conversion
       elsif heat_output_conversion > 0.0
         output_capacity_heat / heat_output_conversion
       else
         0.0
       end
     end
  end

   # Calculates the effective input capacity of a plant (in MW) based on the
   # nominal input capacity and the average effective capacity over
   # the lifetime of a plant.
   # 
   # Assumes 100% when average_effective_output_of_nominal_capacity_over_lifetime
   # is not set (nil).
   #
   # @param [] 
   # 
   # @return [Float] Effective input capacity of a typical plant in MW
   #
   def effective_input_capacity
     function(:effective_input_capacity) do
       nominal_input_capacity * average_effective_output_of_nominal_capacity_over_lifetime
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
   # @param [symbol] 
   #  Unit in which the total cost should be calculated.
   #  Possible units: :unit, :mw, :mwh, :mj, :converter
   #
   # @return [Float] total costs for one unit or plant
   #
  def total_cost
    function(:total_cost) do
      fixed_costs + variable_costs
    end
  end


  ###########################
  # Fixed Costs calculation #
  ###########################
  
  # Calculates the fixed costs of a converter in a given unit.
  # Fixed costs are made up of cost of capital, depreciation costs
  # and fixed operation and maintenance costs.
  #
  # @param []
  #  Unit in which the fixed costs should be calculated.
  #  Possible units: unit, MW, MWh, mj, converter
  #
  # @return [Float]
  #
  def fixed_costs
    function(:fixed_costs) do
      cost_of_capital + depreciation_costs + fixed_operation_and_maintenance_costs
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
      average_investment_costs * wacc * (construction_time + technical_lifetime) / technical_lifetime
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


  ##############################
  # Variable Costs calculation #
  ##############################
  
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
      fuel_costs + co2_emissions_costs + variable_operation_and_maintenance_costs
    end
  end
  
  # Calculates the fuel costs for a single plant, based on the input of fuel
  # for one plant, the 
  def fuel_costs
    function(:fuel_costs) do
      return 0 if real_number_of_units <= 0
      (demand * weighted_carrier_cost_per_mj) / real_number_of_units
    end
  end

  # Calculates the number of units that are installed in the future for this
  # converter, based on the demand (input) of the converter, the effective
  # input capacity and the full_load_seconds of the converter (to effectively)
  # convert MJ and MW 
  def real_number_of_units
    function(:real_number_of_units) do
      demand / (effective_input_capacity * full_load_seconds) rescue 0
    end
  end
  
  # DEBT: rename co2_free and part_ets
  # DEBT: maybe move the factors of how much CO2 has to be paid to a separate
  # function ?
  #
  # input of fuel in mj * the amount of co2 per mj * the co2 price * how much
  # co2 is given away for free * how much of the co2 of this plant is in ETS
  # * how much co2 is not counted (non-energetic or CCS plants) / the number
  # of units
  #
  def co2_emissions_costs
    function(:co2_emissions_costs) do
      return 0 if real_number_of_units <= 0
      (demand * weighted_carrier_co2_per_mj * self.area.co2_price * (1 - self.area.co2_percentage_free) *  part_ets * ((1 - co2_free))) / real_number_of_units
    end
  end
  
  #DEBT: method and attribute have same name!
  def variable_operations_and_maintenance_costs
    function(:variable_operations_and_maintenance_costs) do
      (variable_operation_and_maintenance_costs + variable_operation_and_maintenance_costs_for_ccs) * full_load_hours
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
  # DEBT: It would be better to use the total investment costs in the scatter plot
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
  # DEBT: wrong term. It's not the average investment costs, but it is
  # the investment still left after 50% of the repayment period (which is
  # equal to the construction time + the technical lifetime)
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
  # DEBT: this function should be used for investment costs in the scatter plot of the ETM as well. Move up to public methods if making it so.
  def total_investment_costs
    function(:total_investment_costs) do
      initial_investment_costs + decommissioning_costs
    end
  end


end
