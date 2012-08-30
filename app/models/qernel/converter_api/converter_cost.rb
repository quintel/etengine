class Qernel::ConverterApi



  # Determines the value of the converter at the end of its economical life.
  #
  # Used in calculation of depreciation costs (private method)
  #
  # DEPRECATED
  #
  def end_of_life_value_per_mw_input
    function(:end_of_life_value_per_mw_input) do
      residual_value_per_mw_input - decommissioning_costs_per_mw_input
    end
  end
  
  # The total of the costs of the installation per installed MW of input.
  #
  # Only used inside cost calculation (private method)
  #
  # DEPRECATED
  #
  def initial_investment_costs_per_mw_input
    function(:initial_investment_costs_per_mw_input) do
      sum_unless_empty [
        purchase_price_per_mw_input, 
        installing_costs_per_mw_input, 
        ccs_investment_per_mw_input
      ]
    end
  end
  
  # Total fixed costs per year for the converter.
  #
  # private method
  #
  # DEPRECATED
  #
  def fixed_costs
    function(:fixed_costs) do
      sum_unless_empty [
        cost_of_capital_total, 
        depreciation_total, 
        operation_and_maintenance_cost_fixed
      ]
    end
  end
  
  # The total of fixed costs for the converter per year, based on how many units are required to meet demand.
  #
  # private method
  # 
  # DEPRECATED
  #
  def operation_and_maintenance_cost_fixed
    function(:operation_and_maintenance_cost_fixed) do
      operation_and_maintenance_cost_fixed_per_mw_input * mw_input_capacity
    end
  end
  
  # Total capital cost for the converter per year.
  #
  # Used to be used in several gqueries for electricity and heat
  #
  # DEPRECATED
  #
  def cost_of_capital_total
    function(:cost_of_capital_total) do
      cost_of_capital_per_mw_input * mw_input_capacity
    end
  end
  
  # The capital cost of the converter per MW input.
  #
  # private method
  #
  # DEPRECATED
  #
  def cost_of_capital_per_mw_input
    function(:cost_of_capital_per_mw_input) do
      # construction_time = 0 if construction_time.nil? 
      average_investment_per_mw_input * wacc * ( construction_time + technical_lifetime) / technical_lifetime
    end
  end
  
  # The average investment is determined, to later determine the costs of financing this capital.
  #
  # private method
  #
  # DEPRECATED
  #
  def average_investment_per_mw_input
    function(:average_investment_per_mw_input) do
      (initial_investment_costs_per_mw_input + decommissioning_costs_per_mw_input) / 2
    end
  end
  
  # Calculates the total depreciation for the converter in euros per year. 
  #
  # Used to be used in several gqueries for electricity and heat
  #
  # DEPRECATED
  #
  def depreciation_total
    function(:depreciation_total) do
      depreciation_per_mw_input * mw_input_capacity
    end
  end

  # Calculates the depreciation for the converter in euros per mw input.
  #
  # private method
  #
  # DEPRECATED
  #
  def depreciation_per_mw_input
    function(:depreciation_per_mw_input) do
      (initial_investment_costs_per_mw_input - end_of_life_value_per_mw_input) / technical_lifetime
    end
  end
  
  # Sums the various variable costs.
  #
  # private method
  #
  # DEPRECATED
  #
  def variable_costs
    function(:variable_costs) do
      sum_unless_empty [
        fuel_costs_total, 
        cost_of_co2_emission_credits, 
        operation_and_maintenance_cost_variable_total
      ]
    end
  end
  
  # Sums the various fixed costs per MW input capacity.
  #
  # DEBT: Used in backup option overview chart:
  # /supply/electricity_backup#backup-options 
  # 
  # DEPRECATED
  #
  def fixed_costs_per_mw_input
    function(:fixed_costs_per_mw_input) do
      sum_unless_empty [
        cost_of_capital_per_mw_input, depreciation_per_mw_input, operation_and_maintenance_cost_fixed_per_mw_input
      ]
    end
  end
  
  # Sums the various variable costs per MWh input.
  #
  # DEBT: Used in Merit Order module
  #
  def variable_costs_per_mwh_input
    function(:variable_costs_per_mwh_input) do
      sum_unless_empty [
        operation_and_maintenance_cost_variable_per_mwh_input, 
        fuel_costs_per_mwh_input, 
        cost_of_co2_emission_credits_per_mwh_input
      ]
    end
  end
  
  # Calculates the total variable costs for the converter, including variable CCS costs.
  # 
  # Used to be used in 3 GQL statements that display total O&M costs for all electricity
  # and heat converters
  #
  # DEPRECATED
  #
  def operation_and_maintenance_cost_variable_total
    function(:operation_and_maintenance_cost_variable_total) do
      (operation_and_maintenance_cost_variable_per_full_load_hour + ccs_operation_and_maintenance_cost_per_full_load_hour) * full_load_hours * number_of_units
    end
  end

  # Calculates the variable costs for the converter per MWh input, including variable CCS costs.
  #
  # Private method
  #
  # DEPRECATED
  #
  def operation_and_maintenance_cost_variable_per_mwh_input
    function(:operation_and_maintenance_cost_variable_per_mwh_input) do
      # return 0 if typical_input_capacity_in_mw == 0
      (operation_and_maintenance_cost_variable_per_full_load_hour + ccs_operation_and_maintenance_cost_per_full_load_hour) / typical_input_capacity_in_mw
    end
  end
  
  # The total of all assigned costs for this converter.
  #
  # DEPRECATED: use total_costs_per(:converter)
  #
  def total_costs
    function(:total_costs) do
      sum_unless_empty [
        fixed_costs, 
        variable_costs
      ]
    end
  end
  
  # The total costs of running the converter for 1 MWh of input.
  #
  # Used to calculate total_cost_per_mw_electricity (private method)
  #
  # DEPRECATED
  #
  def total_cost_per_mwh_input
    function(:total_cost_per_mwh_input) do
      variable_costs_per_mwh_input + fixed_costs_per_mw_input / full_load_hours
    end
  end

  # The total costs of running the converter for 1 MWh of electricity.
  #
  # Used to be used in cost scatter plot (y-axis)
  #
  # DEPRECATED: use total_costs_per(:mwh_electricity)
  #
  def total_cost_per_mwh_electricity
    function(:total_cost_per_mwh_electricity) do
      total_cost_per_mwh_input / electricity_output_efficiency
    end
  end

  # The initial investment costs per MW of electricity capacity.
  #
  # Used in cost scatter plot (x-axis)
  #
  # DEPRECATED
  #
  def initial_investment_costs_per_mw_electricity
    function(:initial_investment_costs_per_mw_electricity) do
      # return 0 if electricity_output_efficiency == 0
      initial_investment_costs_per_mw_input / electricity_output_efficiency
    end
  end
  
  ## Returns the purchase price of one unit 
  #
  # Used in ETEngine converter overview page
  #
  def purchase_price_per_unit
    function(:purchase_price_per_unit) do
      purchase_price_per_mw_input * typical_input_capacity_in_mw
    end
  end
end