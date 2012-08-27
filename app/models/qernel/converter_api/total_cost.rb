class Qernel::ConverterApi

  def total_cost_per_mje
    function(:total_cost_per_mje) do
      total_costs / output_of_electricity
    end
  end

  def total_cost_per_mj
    function(:total_cost_per_mj) do
      # prevent division by zero
      total_costs / ( demand * useful_output )
    end
  end


  # Calcutes the total initial investment needed for the entire converter. Also needed in the network calculations.
  #
  def initial_investment_total
    function(:initial_investment_total) do
      number_of_units * initial_investment_costs_per_mw_input * typical_input_capacity_in_mw
    end
  end

  # Returns the cost of installing one unit
  #
  def installing_costs_per_unit
    function(:installing_costs_per_unit) do
      installing_costs_per_mw_input * typical_input_capacity_in_mw
    end
  end

  # Returns the residual value per unit, the amount of money one unit is worth after the economic lifetime has passed
  #
  def residual_value_per_unit
    function(:residual_value_per_unit) do
      residual_value_per_mw_input * typical_input_capacity_in_mw
    end
  end

  def residual_value_per_mwe
    function(:residual_value_per_mwe) do
      residual_value_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end

  # Returns the decommissioning costs per unit
  #
  def decommissioning_costs_per_unit
    function(:decommissioning_costs_per_unit) do
      decommissioning_costs_per_mw_input * typical_input_capacity_in_mw
    end
  end

  def decommissioning_costs_per_mwe
    function(:decommissioning_costs_per_mwe) do
      decommissioning_costs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end

  # Returns the yearly operation and maintenance costs per unit
  #
  def fixed_yearly_operation_and_maintenance_costs_per_unit
    function(:fixed_yearly_operation_and_maintenance_costs_per_unit) do
      operation_and_maintenance_cost_fixed_per_mw_input * typical_input_capacity_in_mw
    end
  end

  def fixed_yearly_operation_and_maintenance_costs_per_mwe
    function(:fixed_yearly_operation_and_maintenance_costs_per_mwe) do
      fixed_yearly_operation_and_maintenance_costs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end

  # Returns the additional initial investment needed for CCS capture per unit.
  #
  def additional_investment_ccs_per_unit
    function(:additional_investment_ccs_per_unit) do
      ccs_investment_per_mw_input * typical_input_capacity_in_mw
    end
  end

  # Returns the total of the purchase price and installation of the unit. Relevant for electricity production.
  #
  def initial_investment_excl_ccs_per_unit
    function(:initial_investment_excl_ccs_per_unit) do
      sum_unless_empty [
        purchase_price_per_unit,
        installing_costs_per_unit
      ]
    end
  end

  def additional_investment_ccs_per_mwe
    function(:additional_investment_ccs_per_mwe) do
      additional_investment_ccs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end

  def initial_investment_excl_ccs_per_mwe
    function(:initial_investment_excl_ccs_per_mwe) do
      initial_investment_excl_ccs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end
end
