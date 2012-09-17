class Qernel::ConverterApi

  # Used in some queries for expert predictions which are
  # not used anymore in the model. 
  #
  # DEBT: Please remove when possible
  #
  def total_cost_per_mje
    function(:total_cost_per_mje) do
      total_costs / output_of_electricity
    end
  end

  # Used in several deprecated gqueries
  #
  # DEPRECATED
  #
  def total_cost_per_mj
    function(:total_cost_per_mj) do
      # prevent division by zero
      total_costs / ( demand * useful_output )
    end
  end


  # Calcutes the total initial investment needed for the entire converter. Also needed in the network calculations.
  #
  # Used to be used in several gqueries for total investment costs.
  #
  # DEPRECATED: use initial_investment_costs_per(converter)
  #
  def initial_investment_total
    function(:initial_investment_total) do
      number_of_units * initial_investment_costs_per_mw_input * typical_input_capacity_in_mw
    end
  end

  # Returns the cost of installing one unit
  #
  # Used in etengine converter overview. Not used in gqueries
  #
  # DEPRECATED: use attribute initial_investment
  #
  def installing_costs_per_unit
    function(:installing_costs_per_unit) do
      installing_costs_per_mw_input * typical_input_capacity_in_mw
    end
  end

  # Returns the residual value per unit, the amount of money one unit is worth after the economic lifetime has passed
  #
  # Used in etengine converter overview. Not used in gqueries
  #
  #  DEPRECATED: use attribute residual_value
  # 
  def residual_value_per_unit
    function(:residual_value_per_unit) do
      residual_value_per_mw_input * typical_input_capacity_in_mw
    end
  end

  # Used in etengine converter overview. Not used in gqueries
  def residual_value_per_mwe
    function(:residual_value_per_mwe) do
      residual_value_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end

  # Returns the decommissioning costs per unit
  #
  # DEPRECATED: use attribute decommissioning_costs
  #
  # Used in etengine converter overview. Not used in gqueries
  def decommissioning_costs_per_unit
    function(:decommissioning_costs_per_unit) do
      decommissioning_costs_per_mw_input * typical_input_capacity_in_mw
    end
  end

  # Used in etengine converter overview. Not used in gqueries
  def decommissioning_costs_per_mwe
    function(:decommissioning_costs_per_mwe) do
      decommissioning_costs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end

  # Returns the yearly operation and maintenance costs per unit
  #
  # Used in etengine converter overview. Not used in gqueries
  def fixed_yearly_operation_and_maintenance_costs_per_unit
    function(:fixed_yearly_operation_and_maintenance_costs_per_unit) do
      operation_and_maintenance_cost_fixed_per_mw_input * typical_input_capacity_in_mw
    end
  end

  # Used in etengine converter overview. Not used in gqueries
  def fixed_yearly_operation_and_maintenance_costs_per_mwe
    function(:fixed_yearly_operation_and_maintenance_costs_per_mwe) do
      fixed_yearly_operation_and_maintenance_costs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end

  # Returns the additional initial investment needed for CCS capture per unit.
  #
  # Used in etengine converter overview. Not used in gqueries
  def additional_investment_ccs_per_unit
    function(:additional_investment_ccs_per_unit) do
      ccs_investment_per_mw_input * typical_input_capacity_in_mw
    end
  end

  # Returns the total of the purchase price and installation of the unit. Relevant for electricity production.
  #
  # Used in etengine converter overview. Not used in gqueries
  def initial_investment_excl_ccs_per_unit
    function(:initial_investment_excl_ccs_per_unit) do
      sum_unless_empty [
        purchase_price_per_unit,
        installing_costs_per_unit
      ]
    end
  end

  # Used in etengine converter overview. Not used in gqueries
  def additional_investment_ccs_per_mwe
    function(:additional_investment_ccs_per_mwe) do
      additional_investment_ccs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end

  # Used in etengine converter overview. Not used in gqueries
  def initial_investment_excl_ccs_per_mwe
    function(:initial_investment_excl_ccs_per_mwe) do
      initial_investment_excl_ccs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end
end
