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


  def fuel_cost_raw_material_per_mj
    dataset_fetch_handle_nil(:fuel_cost_raw_material_per_mj) do
      # sum_unless_empty converter.inputs.map{|input|
      #   (useful_output == 0.0) ? 0.0 : ((input.carrier.cost_per_mj || 0.0) * input.conversion / useful_output)
      # }
        (useful_output == 0.0) ? 0.0 : (weighted_carrier_cost_per_mj / useful_output)
    end
  end
  attributes_required_for :fuel_cost_raw_material_per_mj, [:useful_output]


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


  def fuel_cost_raw_material_for_carrier(carrier)
    supply = converter.output(carrier)
    supply = supply and supply.expected_value
    price = carrier.cost_per_mj
    return nil if [supply, price].any?(&:nil?)

    supply * price
  end

end
