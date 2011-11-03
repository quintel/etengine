class Qernel::ConverterApi

  def total_cost_per_mje
    dataset_fetch_handle_nil(:total_cost_per_mje) do
      total_costs / output_of_electricity
    end
  end
  attributes_required_for :total_cost_per_mje, [
    :total_costs,
    :output_of_electricity
  ]

  def total_cost_per_mj
    dataset_fetch_handle_nil(:total_cost_per_mj) do
      # prevent division by zero
      total_costs / ( demand * useful_output )  rescue nil
    end
  end
  attributes_required_for :total_cost_per_mj, [
    :total_costs,
    :useful_output,
    :demand
  ]

  ##
  # Removed total_cost, refactored to total_costs
  # Added an alias untill the queries are altered
  #
  alias total_cost total_costs

  ##
  # Removed total_cost_electricity, it now has the same results then total_costs
  # Added an alias untill the queries are altered
  #
  alias total_cost_electricity total_costs

  ## Calcutes the total initial investment needed for the entire converter. Also needed in the network calculations. 
  #
  def initial_investment_total
    dataset_fetch_handle_nil(:initial_investment_total) do
      number_of_units * initial_investment_costs_per_mw_input * typical_nominal_input_capacity
    end
  end
  attributes_required_for :initial_investment_total, [
    :initial_investment_costs_per_mw_input,
    :typical_nominal_input_capacity,
    :number_of_units
  ]

  ## Returns the cost of installing one unit 
  #
  
  def cost_of_installing_per_unit
    dataset_fetch_handle_nil(:cost_of_installing_per_unit) do
      installing_costs_per_mw_input * typical_nominal_input_capacity
    end
  end
  attributes_required_for :cost_of_installing_per_unit, [
  :installing_costs_per_mw_input,
  :typical_nominal_input_capacity
  ]
  
  ## Returns the cost of installing one mwe 
  #
  
  def cost_of_installing_per_mwe
    dataset_fetch_handle_nil(:cost_of_installing_per_mwe) do
      cost_of_installing_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end
  attributes_required_for :cost_of_installing_per_mwe, [
  :cost_of_installing_per_unit,
  :nominal_capacity_electricity_output_per_unit
  ]
  
  ## Returns the residual value per unit, the amount of money one unit is worth after the economic lifetime has passed 
  #
  def residual_value_per_unit
    dataset_fetch_handle_nil(:residual_value_per_unit) do
      residual_value_per_mw_input * typical_nominal_input_capacity
    end
  end
  attributes_required_for :residual_value_per_unit, [
    :residual_value_per_mw_input,
    :typical_nominal_input_capacity
  ]


  def residual_value_per_mwe
    dataset_fetch_handle_nil(:residual_value_per_mwe) do
      residual_value_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end
  attributes_required_for :residual_value_per_mwe, [
    :residual_value_per_unit,
    :nominal_capacity_electricity_output_per_unit
  ]
  
  ## Returns the decommissioning costs per unit 
  #
  def decommissioning_costs_per_unit
    dataset_fetch_handle_nil(:decommissioning_costs_per_unit) do
      decommissioning_costs_per_mw_input * typical_nominal_input_capacity
    end
  end
  attributes_required_for :decommissioning_costs_per_unit, [
    :decommissioning_costs_per_mw_input,
    :typical_nominal_input_capacity
  ]
  
  def decommissioning_costs_per_mwe
    dataset_fetch_handle_nil(:decommissioning_costs_per_mwe) do
      decommissioning_costs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end
  attributes_required_for :decommissioning_costs_per_mwe, [
    :decommissioning_costs_per_unit,
    :nominal_capacity_electricity_output_per_unit
  ]

  ## Returns the yearly operation and maintenance costs per unit  
  #
  def fixed_yearly_operation_and_maintenance_costs_per_unit
    dataset_fetch_handle_nil(:fixed_yearly_operation_and_maintenance_costs_per_unit) do
      operation_and_maintenance_cost_fixed_per_mw_input * typical_nominal_input_capacity
    end
  end
  
  attributes_required_for :fixed_yearly_operation_and_maintenance_costs_per_unit, [
    :decommissioning_costs_per_mw_input,
    :typical_nominal_input_capacity
  ]

  def fixed_yearly_operation_and_maintenance_costs_per_mwe
    dataset_fetch_handle_nil(:fixed_yearly_operation_and_maintenance_costs_per_mwe) do
      fixed_yearly_operation_and_maintenance_costs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end
  
  attributes_required_for :fixed_yearly_operation_and_maintenance_costs_per_mwe, [
    :fixed_yearly_operation_and_maintenance_costs_per_unit,
    :nominal_capacity_electricity_output_per_unit
  ]

  
  ## Returns the additional initial investment needed for CCS capture per unit. 
  #
  def additional_investment_ccs_per_unit
    dataset_fetch_handle_nil(:additional_investment_ccs_per_unit) do
      ccs_investment_per_mw_input * typical_nominal_input_capacity
    end
  end
  attributes_required_for :additional_investment_ccs_per_unit, [
    :ccs_investment_per_mw_input,
    :typical_nominal_input_capacity
  ]
  
  ## Returns the total of the purchase price and installation of the unit. Relevant for electricity production. 
  #
  def initial_investment_excl_ccs_per_unit
    sum_unless_empty values_for_method(:initial_investment_excl_ccs_per_unit)
  end
  attributes_required_for :initial_investment_excl_ccs_per_unit, [
    :purchase_price_per_unit,
    :cost_of_installing_per_unit
  ]
  
  
  def additional_investment_ccs_per_mwe
    dataset_fetch_handle_nil(:additional_investment_ccs_per_mwe) do
      ccs_investment_per_mw_input / nominal_capacity_electricity_output_per_unit
    end
  end
  attributes_required_for :additional_investment_ccs_per_mwe, [
    :additional_investment_ccs_per_unit,
    :nominal_capacity_electricity_output_per_unit
  ]
  
  def initial_investment_excl_ccs_per_mwe
    dataset_fetch_handle_nil(:initial_investment_excl_ccs_per_mwe) do
      initial_investment_excl_ccs_per_unit / nominal_capacity_electricity_output_per_unit
    end
  end
  attributes_required_for :initial_investment_excl_ccs_per_mwe, [
    :initial_investment_excl_ccs_per_unit,
    :nominal_capacity_electricity_output_per_unit
  ]
  
  
  def cost_of_inputs
    dataset_fetch(:cost_of_inputs) do
      converter.inputs.map do |input_slot|
        (input_slot.carrier.cost_per_mj || 0.0) * converter.demand
      end
    end
  end
  register_calculation_method :cost_of_inputs

  def cost_of_outputs
    dataset_fetch(:cost_of_outputs) do
      converter.outputs.map do |output_slot|
        (output_slot.carrier.cost_per_mj || 0.0) * converter.demand
      end
    end
  end
  register_calculation_method :cost_of_outputs
end
