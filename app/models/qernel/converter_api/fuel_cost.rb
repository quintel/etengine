class Qernel::ConverterApi

  def fuel_cost_raw_material_per_mje
    dataset_fetch_handle_nil(:fuel_cost_raw_material_per_mje) do
      electricity_conversion = converter.outputs.select{|output|
       output.carrier === :electricity
       }.first.conversion
      (electricity_conversion == 0.0) ? 0.0 : (weighted_carrier_cost_per_mj / electricity_conversion)
    end
  end
  attributes_required_for :fuel_cost_raw_material_per_mje, [:electricity_output]
  unit_for_calculation :fuel_cost_raw_material_per_mje, 'euro'


  def fuel_cost_raw_material_per_mj
    dataset_fetch_handle_nil(:fuel_cost_raw_material_per_mj) do
      (useful_output == 0.0) ? 0.0 : (weighted_carrier_cost_per_mj / useful_output)
    end
  end
  attributes_required_for :fuel_cost_raw_material_per_mj, [:useful_output]
  unit_for_calculation :fuel_cost_raw_material_per_mj, 'euro'


  def electricity_output
    c = converter.output(:electricity)
    c and c.conversion
  end

  def sustainable_input_factor
    dataset_fetch(:sustainable_input_factor) do
      converter.inputs.map{|slot| (slot.carrier.sustainable || 0.0) * slot.conversion }.compact.sum
    end
  end

  #TODO: this method returns a share. But the name presumes it is not!
  def useful_output
    dataset_fetch(:useful_output) do
      [ converter.output(:electricity),
        converter.output(:useable_heat),
        converter.output(:steam_hot_water),
        converter.output(:hot_water)
      ].map{|c| c and c.conversion }.compact.sum
    end
  end

  # TODO: Dry up with useful_output
  def useful_heat_output
    dataset_fetch(:useful_output) do
      [
        converter.output(:useable_heat),
        converter.output(:steam_hot_water),
        converter.output(:hot_water)
      ].map{|c| c and c.conversion }.compact.sum
    end
  end

  # QUESTION: Is this used? 08-02-2011 RD
  def fuel_cost_raw_material_for_carrier_per_mj(carrier)
    converter.output(carrier).expected_value
  end


  def fuel_cost_raw_material
    dataset_fetch(:fuel_cost_raw_material) do
      carriers = converter.input_carriers
      prices = carriers.map {|carrier| fuel_cost_raw_material_for_carrier(carrier) }

      sum_unless_empty prices
    end
  end

  # Determines the fuel costs, bases on the weighted costs of the used input.
  #
  def fuel_costs_total
    dataset_fetch_handle_nil(:fuel_costs_total) do
      demand * weighted_carrier_cost_per_mj
    end
  end
  attributes_required_for :fuel_costs_total, [
    :demand, :weighted_carrier_cost_per_mj
  ]

  # Determines the fuel costs per MWh input, bases on the weighted costs of the used input.
  #
  def fuel_costs_per_mwh_input
    dataset_fetch_handle_nil(:fuel_costs_per_mwh_input) do
      SECS_PER_HOUR * weighted_carrier_cost_per_mj
    end
  end
  attributes_required_for :fuel_costs_per_mwh_input, [:weighted_carrier_cost_per_mj  ]


  def fuel_cost_raw_material_for_carrier(carrier)
    supply = converter.output(carrier)
    supply = supply and supply.expected_value
    price = carrier.cost_per_mj
    return nil if [supply, price].any?(&:nil?)

    supply * price
  end

end
