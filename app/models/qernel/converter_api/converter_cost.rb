class Qernel::ConverterApi



  # Determines the value of the converter at the end of its economical life.
  #
  def end_of_life_value_per_mw_input
    dataset_fetch_handle_nil(:end_of_life_value_per_mw_input) do
      residual_value_per_mw_input - decommissioning_costs_per_mw_input
    end
  end
  attributes_required_for :end_of_life_value_per_mw_input, [
    :residual_value_per_mw_input, :decommissioning_costs_per_mw_input
  ]

  # The total of the costs of the installation per installed MW of input.
  #
  def initial_investment_costs_per_mw_input
    dataset_fetch(:initial_investment_costs_per_mw_input) do
      sum_unless_empty values_for_method(:initial_investment_costs_per_mw_input)
    end
  end
  attributes_required_for :initial_investment_costs_per_mw_input, [
    :purchase_price_per_mw_input, :installing_costs_per_mw_input, :ccs_investment_per_mw_input
  ]

  # Total fixed costs per year for the converter.
  #
  def fixed_costs
    dataset_fetch(:fixed_costs) do
      sum_unless_empty values_for_method(:fixed_costs)
    end
  end
  attributes_required_for :fixed_costs, [
    :cost_of_capital_total, :depreciation_total, :operation_and_maintenance_cost_fixed]

  # The total of fixed costs for the converter per year, based on how many units are required to meet demand.
  #
  def operation_and_maintenance_cost_fixed
    dataset_fetch_handle_nil(:operation_and_maintenance_cost_fixed) do
      operation_and_maintenance_cost_fixed_per_mw_input * mw_input_capacity
    end
  end
  attributes_required_for :operation_and_maintenance_cost_fixed, [
    :operation_and_maintenance_cost_fixed_per_mw_input, :mw_input_capacity
  ]

  # Total capital cost for the converter per year.
  #
  def cost_of_capital_total
    dataset_fetch_handle_nil(:cost_of_capital_total) do
      cost_of_capital_per_mw_input * mw_input_capacity
    end
  end
  attributes_required_for :cost_of_capital_total, [
    :cost_of_capital_per_mw_input, :mw_input_capacity
  ]

  # The capital cost of the converter per MW input.
  #
  def cost_of_capital_per_mw_input
    dataset_fetch_handle_nil(:cost_of_capital_per_mw_input) do
      # construction_time = 0 if construction_time.nil? 
      average_investment_per_mw_input * wacc * ( construction_time + technical_lifetime) / technical_lifetime
    end
  end
  attributes_required_for :cost_of_capital_per_mw_input, [
    :average_investment_per_mw_input, :wacc, :technical_lifetime,:construction_time
  ]

  # The average investment is determined, to later determine the costs of financing this capital.
  #
  def average_investment_per_mw_input
    dataset_fetch_handle_nil(:average_investment_per_mw_input) do
      (initial_investment_costs_per_mw_input + decommissioning_costs_per_mw_input) / 2
    end
  end
  attributes_required_for :average_investment_per_mw_input, [
    :initial_investment_costs_per_mw_input, :decommissioning_costs_per_mw_input
  ]

  # Calculates the total depreciation for the converter in euros per year. 
  #
  def depreciation_total
    dataset_fetch_handle_nil(:depreciation_total) do
      depreciation_per_mw_input * mw_input_capacity
    end
  end
  attributes_required_for :depreciation_total, [
    :mw_input_capacity, :depreciation_per_mw_input]

  # Calculates the depreciation for the converter in euros per mw input.
  #
  def depreciation_per_mw_input
    dataset_fetch_handle_nil(:depreciation_per_mw_input) do
      (initial_investment_costs_per_mw_input - end_of_life_value_per_mw_input) / technical_lifetime
    end
  end
  attributes_required_for :depreciation_per_mw_input, [
    :initial_investment_costs_per_mw_input, :end_of_life_value_per_mw_input, :technical_lifetime
  ]

  # Sums the various variable costs.
  #
  def variable_costs
    dataset_fetch(:variable_costs) do
      sum_unless_empty values_for_method(:variable_costs)
    end
  end
  attributes_required_for :variable_costs, [
    :fuel_costs_total, :cost_of_co2_emission_credits, :operation_and_maintenance_cost_variable_total
  ]

  # Sums the various fixed costs per MW input capacity.
  #
  def fixed_costs_per_mw_input
    dataset_fetch(:fixed_costs_per_mw_input) do
      sum_unless_empty values_for_method(:fixed_costs_per_mw_input)
    end
  end
  attributes_required_for :fixed_costs_per_mw_input, [
    :cost_of_capital_per_mw_input, :depreciation_per_mw_input, :operation_and_maintenance_cost_fixed_per_mw_input
  ]

  # Sums the various variable costs per MWh input.
  #
  def variable_costs_per_mwh_input
    dataset_fetch(:variable_costs_per_mwh_input) do
      sum_unless_empty values_for_method(:variable_costs_per_mwh_input)
    end
  end
  attributes_required_for :variable_costs_per_mwh_input, [
    :operation_and_maintenance_cost_variable_per_mwh_input, :fuel_costs_per_mwh_input, :cost_of_co2_emission_credits_per_mwh_input
  ]

# Calculates the total variable costs for the converter, including variable CCS costs.
  #
  def operation_and_maintenance_cost_variable_total
    dataset_fetch_handle_nil(:operation_and_maintenance_cost_variable_total) do
      (operation_and_maintenance_cost_variable_per_full_load_hour + ccs_operation_and_maintenance_cost_per_full_load_hour) * full_load_hours * number_of_units
    end
  end
  attributes_required_for :operation_and_maintenance_cost_variable_total, [
    :number_of_units, :ccs_operation_and_maintenance_cost_per_full_load_hour, :operation_and_maintenance_cost_variable_per_full_load_hour, :full_load_hours
  ]

# Calculates the variable costs for the converter per MWh input, including variable CCS costs.
  #
  def operation_and_maintenance_cost_variable_per_mwh_input
    dataset_fetch_handle_nil(:operation_and_maintenance_cost_variable_per_mwh_input) do
      # return 0 if typical_input_capacity == 0
      (operation_and_maintenance_cost_variable_per_full_load_hour + ccs_operation_and_maintenance_cost_per_full_load_hour) / typical_input_capacity
    end
  end
  attributes_required_for :operation_and_maintenance_cost_variable_per_mwh_input, [
    :operation_and_maintenance_cost_variable_per_full_load_hour, :typical_input_capacity
  ]

  # The total of all assigned costs for this converter.
  def total_costs
    dataset_fetch(:total_costs) do
      sum_unless_empty values_for_method(:total_costs)
    end
  end
  attributes_required_for :total_costs, [:fixed_costs, :variable_costs]

  # The total costs of running the converter for 1 MWh of input.
  def total_cost_per_mwh_input
    dataset_fetch_handle_nil(:total_cost_per_mwh_input) do
      variable_costs_per_mwh_input + fixed_costs_per_mw_input / full_load_hours
    end
  end
  attributes_required_for :total_cost_per_mwh_input, [:variable_costs_per_mwh_input, :fixed_costs_per_mw_input, :full_load_hours]

  # The total costs of running the converter for 1 MWh of electricity.
  def total_cost_per_mwh_electricity
    dataset_fetch_handle_nil(:total_cost_per_mwh_electricity) do
      total_cost_per_mwh_input / electricity_output_efficiency
    end
  end
  attributes_required_for :total_cost_per_mwh_electricity, [:total_cost_per_mwh_input, :electricity_output_efficiency]

  # The initial investment costs per MW of electricity capacity.
  def initial_investment_costs_per_mw_electricity
    dataset_fetch_handle_nil(:initial_investment_costs_per_mw_electricity) do
      # return 0 if electricity_output_efficiency == 0
      initial_investment_costs_per_mw_input / electricity_output_efficiency
    end
  end
  attributes_required_for :initial_investment_costs_per_mw_electricity, [:initial_investment_costs_per_mw_input, :electricity_output_efficiency]

  ## Returns the purchase price of one unit 
  #
  def purchase_price_per_unit
    dataset_fetch_handle_nil(:purchase_price_per_unit) do
      purchase_price_per_mw_input * typical_nominal_input_capacity
    end
  end
  attributes_required_for :purchase_price_per_unit, [
    :purchase_price_per_mw_input,
    :typical_nominal_input_capacity
  ]
end