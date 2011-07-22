class Qernel::ConverterApi

  def total_cost_per_mje
    dataset_fetch(:total_cost_per_mje) do
      sum_unless_empty values_for_method(:total_cost_per_mje)
    end
  end
  attributes_required_for :total_cost_per_mje, [
    :cost_om_per_mj,
    :fuel_cost_raw_material_per_mje,
    :cost_fuel_other_per_mj, # TODO change back to: cost_fuel_other_per_mj
    :cost_co2_per_mj_output,
    :finance_and_capital_cost
  ]

  def total_cost_per_mje_excl_co2_and_fuel
    dataset_fetch(:total_cost_per_mje_excl_co2_and_fuel) do
      sum_unless_empty values_for_method(:total_cost_per_mje_excl_co2_and_fuel)
    end
  end
  attributes_required_for :total_cost_per_mje_excl_co2_and_fuel, [
    :cost_om_per_mj,
    :cost_fuel_other_per_mj, # TODO change back to: cost_fuel_other_per_mj
    :finance_and_capital_cost
  ]


  def total_cost_per_mj
    dataset_fetch(:total_cost_per_mj) do
      sum_unless_empty values_for_method(:total_cost_per_mj)
    end
  end
  attributes_required_for :total_cost_per_mj, [
    :cost_om_per_mj,
    :fuel_cost_raw_material_per_mj,
    :cost_fuel_other_per_mj,
    :cost_co2_per_mj_output,
    :finance_and_capital_cost
  ]


  def total_cost
    dataset_fetch_handle_nil(:total_cost) do
      total_cost_per_mj * demand * useful_output
    end
  end
  attributes_required_for :total_cost, [:total_cost_per_mje, :demand, :useful_output]


  def total_cost_electricity
    dataset_fetch_handle_nil(:total_cost_electricity) do
      total_cost_per_mje * demand * electricity_output
    end
  end
  attributes_required_for :total_cost_electricity, [:total_cost_per_mje, :demand, :electricity_output]

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
