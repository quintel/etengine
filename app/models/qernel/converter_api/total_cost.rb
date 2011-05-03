class Qernel::ConverterApi

  def total_cost_per_mje
    sum_unless_empty values_for_method(:total_cost_per_mje)
  end
  attributes_required_for :total_cost_per_mje, [
    :cost_om_per_mj,
    :fuel_cost_raw_material_per_mje,
    :cost_fuel_other_per_mj, # TODO change back to: cost_fuel_other_per_mj
    :cost_co2_per_mj_output,
    :finance_and_capital_cost
  ]

  def total_cost_per_mje_excl_co2_and_fuel
    sum_unless_empty values_for_method(:total_cost_per_mje_excl_co2_and_fuel)
  end
  attributes_required_for :total_cost_per_mje_excl_co2_and_fuel, [
    :cost_om_per_mj,
    :cost_fuel_other_per_mj, # TODO change back to: cost_fuel_other_per_mj
    :finance_and_capital_cost
  ]


  def total_cost_per_mj
    sum_unless_empty values_for_method(:total_cost_per_mj)
  end
  attributes_required_for :total_cost_per_mj, [
    :cost_om_per_mj,
    :fuel_cost_raw_material_per_mj,
    :cost_fuel_other_per_mj,
    :cost_co2_per_mj_output,
    :finance_and_capital_cost
  ]


  def total_cost
    if required_attributes_contain_nil?(:total_cost)
      nil
    else
      total_cost_per_mj * demand * useful_output
    end
  end
  attributes_required_for :total_cost, [:total_cost_per_mje, :demand, :useful_output]


  def total_cost_electricity
    return nil if required_attributes_contain_nil?(:total_cost_electricity)

    total_cost_per_mje * demand * electricity_output
  end
  attributes_required_for :total_cost_electricity, [:total_cost_per_mje, :demand, :electricity_output]

  def cost_of_inputs
    converter.inputs.map do |input_slot|
      (input_slot.carrier.cost_per_mj || 0.0) * converter.demand
    end
  end
  register_calculation_method :cost_of_inputs

  def cost_of_outputs
    converter.outputs.map do |output_slot|
      (output_slot.carrier.cost_per_mj || 0.0) * converter.demand
    end
  end
  register_calculation_method :cost_of_outputs
end
