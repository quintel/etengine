class Qernel::ConverterApi

  def sustainable_input_factor
    function(:sustainable_input_factor) do
      converter.inputs.map{|slot| (slot.carrier.sustainable || 0.0) * slot.conversion }.compact.sum
    end
  end

  #TODO: this method returns a share. But the name presumes it is not!
  def useful_output
    function(:useful_output) do
      [ converter.output(:electricity),
        converter.output(:useable_heat),
        converter.output(:steam_hot_water)
      ].map{|c| c and c.conversion }.compact.sum
    end
  end
  unit_for_calculation "useful_output", 'factor'
  
  # Determines the fuel costs, bases on the weighted costs of the used input.
  #
  def fuel_costs_total
    function(:fuel_costs_total) do
      demand * weighted_carrier_cost_per_mj
    end
  end
  unit_for_calculation "fuel_costs_total", 'euro'
  
  # Determines the fuel costs per MWh input, bases on the weighted costs of the used input.
  #
  def fuel_costs_per_mwh_input
    function(:fuel_costs_per_mwh_input) do
      SECS_PER_HOUR * weighted_carrier_cost_per_mj
    end
  end
  unit_for_calculation "fuel_costs_per_mwh_input", 'euro'

end
