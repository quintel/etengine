class Qernel::ConverterApi

  def total_cost_per_mje
    #output_of_electricity == 0.0
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
      total_costs / ( demand * useful_output )
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
