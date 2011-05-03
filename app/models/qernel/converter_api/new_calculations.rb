class Qernel::ConverterApi

  # Determines the value of the converter at the end of its economical life.
  #
  def end_of_life_value_per_mw_input
    return nil if required_attributes_contain_nil?(:end_of_life_value_per_mw_input)
    residual_value_per_mw_input - decommissioning_costs_per_mw_input
  end
  attributes_required_for :end_of_life_value_per_mw_input, [
    :residual_value_per_mw_input, :decommissioning_costs_per_mw_input]

  # The total of the costs of the installation per installed MW of input.
  #
  def initial_investment_per_mw_input
    sum_unless_empty values_for_method(:initial_investment_per_mw_input)
  end
  attributes_required_for :initial_investment_per_mw_input, [
    :purchase_price_per_mw_input, :installing_costs_per_mw_input  ]

  # Total fixed costs per year for the converter.
  #
  def fixed_costs
    sum_unless_empty values_for_method(:fixed_costs)
  end
  attributes_required_for :fixed_costs, [
    :cost_of_capital_total, :depreciation_total, :fixed_operation_and_maintenance_cost]

  # The total of fixed costs for the converter per year, based on how many units are required to meet demand.
  #
  def fixed_operation_and_maintenance_cost
    return nil if required_attributes_contain_nil?(:fixed_operation_and_maintenance_cost)

    fixed_operation_and_maintenance_cost_per_mw_input * required_input_capacity
  end
  attributes_required_for :fixed_operation_and_maintenance_cost, [
    :fixed_operation_and_maintenance_cost_per_mw_input, :required_input_capacity  ]

  # Total capital cost for the converter per year.
  #
  def cost_of_capital_total
    return nil if required_attributes_contain_nil?(:cost_of_capital_total)

    cost_of_capital_per_mw_input * required_input_capacity
  end
  attributes_required_for :cost_of_capital_total, [
    :cost_of_capital_per_mw_input, :required_input_capacity]

  # The capital cost of the converter per MW input.
  #
  def cost_of_capital_per_mw_input
    return nil if required_attributes_contain_nil?(:cost_of_capital_per_mw_input)

    average_investment_per_mw_input * wacc * ( construction_time + economic_lifetime) / economic_lifetime
  end
  attributes_required_for :cost_of_capital_per_mw_input, [
    :average_investment_per_mw_input, :wacc, :construction_time, :economic_lifetime]

  # The average investment is determined, to later determine the costs of financing this capital.
  #
  def average_investment_per_mw_input
    return nil if required_attributes_contain_nil?(:average_investment_per_mw_input)

    (initial_investment_per_mw_input + end_of_life_value_per_mw_input) / 2
  end
  attributes_required_for :average_investment_per_mw_input, [
    :initial_investment_per_mw_input, :end_of_life_value_per_mw_input]

  # Calculates the total depreciation for the converter in euros per year. 
  #
  def depreciation_total
    return nil if required_attributes_contain_nil?(:depreciation_total)

    depreciation_per_mw_input * required_input_capacity
  end
  attributes_required_for :depreciation_total, [
    :required_input_capacity, :depreciation_per_mw_input]

  # Calculates the depreciation for the converter in euros per mw input.
  #
  def depreciation_per_mw_input
    return nil if required_attributes_contain_nil?(:depreciation_per_mw_input)

    (initial_investment_per_mw_input - end_of_life_value_per_mw_input) / economic_lifetime
  end
  attributes_required_for :depreciation_per_mw_input, [
    :initial_investment_per_mw_input, :end_of_life_value_per_mw_input, :economic_lifetime]

  # Sums the various variable costs.
  #
  def variable_costs
    return nil if required_attributes_contain_nil?(:variable_costs)

    fuel_costs + cost_of_co2_emission_credits + (operation_and_maintenance_cost_variable * full_load_hours)
  end
  attributes_required_for :variable_costs, [
    :fuel_costs, :cost_of_co2_emission_credits, :operation_and_maintenance_cost_variable, :full_load_hours]

  # Determines the fuel costs, bases on the weighted costs of the used input.
  #
  def fuel_costs
    return nil if required_attributes_contain_nil?(:fuel_costs)
    demand * weighted_carrier_cost_per_mj
  end
  attributes_required_for :fuel_costs, [
    :demand, :weighted_carrier_cost_per_mj  ]

  # This returns the costs for co2 emission credits, as it multiplies the CO2 emitted by the converter by the price of the CO2 emissions.
  #
  def cost_of_co2_emission_credits
    return nil if required_attributes_contain_nil?(:cost_of_co2_emission_credits)
    
    (1 - self.area.co2_percentage_free ) * co2_of_input * self.area.co2_price * part_ets

  end
  attributes_required_for :cost_of_co2_emission_credits, [:co2_of_input, :part_ets]

  # The total of all assigned costs for this converter 
  #
  def total_costs
    sum_unless_empty values_for_method(:total_costs)
  end
  attributes_required_for :total_costs, [:fixed_costs, :variable_costs]

  # The input capacity that is required to provide the demand.
  #
  def required_input_capacity
    return nil if required_attributes_contain_nil?(:required_input_capacity)

    demand / full_load_seconds
  end
  attributes_required_for :required_input_capacity, [:demand, :full_load_seconds]

  # How many units are required to fill demand.
  #
  def number_of_units
    return nil if required_attributes_contain_nil?(:number_of_units)

    required_input_capacity / typical_input_capacity
  end
  attributes_required_for :number_of_units, [:required_input_capacity, :typical_input_capacity]

  # How many seconds a year the converters runs at full load. 
  # This is useful because MJ is MW per second.
  def full_load_seconds
    return nil if required_attributes_contain_nil?(:full_load_seconds)

    full_load_hours * SECS_PER_HOUR
  end
  attributes_required_for :full_load_seconds, [:full_load_hours]

end