class Qernel::ConverterApi

  def demand_of_fossil
    dataset_fetch(:demand_of_fossil) do
      converter.input_carriers.map do |carrier|
        if carrier.sustainable and demand = demand_of_carrier(carrier)
          demand * (1 - carrier.sustainable)
        end
      end.compact.sum
    end
  end
  alias_method :output_of_fossil, :demand_of_fossil

  def demand_of_sustainable
    dataset_fetch(:demand_of_sustainable) do
      converter.input_carriers.map do |carrier|
        if carrier.sustainable and demand = demand_of_carrier(carrier)
          demand * carrier.sustainable
        end
      end.compact.sum
    end
  end
  alias_method :output_of_sustainable, :demand_of_sustainable

  def output_of(*carriers)
    carriers.map do |c| 
      key = c.respond_to?(:key) ? c.key : c
      output_of_carrier(key)
    end.compact.sum
  end

  def output_of_carrier(carrier)
    c = converter.output(carrier)
    (c and c.external_value) || 0.0
  end


  # Helper method to get all heat inputs (useable_heat, hot_water, steam_hot_wather)
  #
  def input_of_heat_carriers
    dataset_fetch(:input_of_heat_carriers) do
      input_of_useable_heat + input_of_hot_water + input_of_steam_hot_water
    end
  end

  # Helper method to get all heat outputs (useable_heat, hot_water, steam_hot_wather)
  #
  def output_of_heat_carriers
    dataset_fetch(:input_of_heat_carriers) do
      output_of_useable_heat + output_of_hot_water + output_of_steam_hot_water
    end
  end
  
  def output_of_heat_and_cooling_carriers
    dataset_fetch(:output_of_heat_and_cooling_carriers) do
      output_of_useable_heat + output_of_hot_water + output_of_steam_hot_water + output_of_cooling
    end
  end

  def input_of_fossil_carriers
    dataset_fetch(:input_of_fossil_carriers) do
      input_of_coal + input_of_crude_oil + input_of_natural_gas + input_of_diesel + input_of_gasoline + input_of_steam_hot_water + input_of_gas_power_fuelmix
    end
  end

  def input_of_biomass_group
    dataset_fetch(:input_of_biomass_group) do
      input_of_greengas + input_of_biodiesel + input_of_algae_diesel + input_of_biogas + input_of_bio_ethanol + input_of_wood_pellets + input_of_wood + input_of_torrified_biomass_pellets 
    end
  end
  
  def input_of_ambient_carriers
    dataset_fetch(:input_of_ambient_carriers) do
      input_of_ambient_heat + input_of_solar_radiation + input_of_ambient_cold + input_of_wind
    end
  end
  
  def demand_of_carrier(carrier)
    Rails.logger.info('demand_of_* is deprecated. Use output_of_* instead')
    output_of_carrier(carrier)
  end


  def input_of(*carriers)
    carriers.map do |c| 
      key = c.respond_to?(:key) ? c.key : c
      input_of_carrier(key)
    end.compact.sum
  end

  def input_of_carrier(carrier)
    c = converter.input(carrier)
    (c and c.external_value) || 0.0
  end

  def supply_of_carrier(carrier)
    Rails.logger.info('supply_of_* is deprecated. Use input_of_* instead')
    input_of_carrier(carrier)
  end

  def electricity_output_efficiency
    dataset_fetch(:electricity_output_efficiency) do
      c = converter.output(:electricity)
      c and c.conversion
    end
  end

  def loss_ex_input_loss
    dataset_fetch(:loss_ex_input_loss) do
      out = converter.output(:loss)
      out = out and out.expected_value
      inp = converter.input(:loss)
      inp = inp and inp.expected_value
      (out || 0.0) - (inp || 0.0)
    end
  end

end
