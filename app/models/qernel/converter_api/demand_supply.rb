class Qernel::ConverterApi

  def demand_of_fossil
    fetch(:demand_of_fossil) do
      converter.input_carriers.map do |carrier|
        if carrier.sustainable and demand = demand_of_carrier(carrier)
          demand * (1 - carrier.sustainable)
        end
      end.compact.sum
    end
  end
  alias_method :output_of_fossil, :demand_of_fossil

  def demand_of_sustainable
    fetch(:demand_of_sustainable) do
      converter.input_carriers.map do |carrier|
        if carrier.sustainable and demand = demand_of_carrier(carrier)
          demand * carrier.sustainable
        end
      end.compact.sum
    end
  end
  alias_method :output_of_sustainable, :demand_of_sustainable

  def input_of_loss
    if converter.demand
      converter.demand - converter.inputs.reject(&:loss?).map(&:external_value).compact.sum
    else
      0.0
    end
  end
  unit_for_calculation "input_of_loss", 'MJ'


  def output_of_loss
    if converter.demand
      converter.demand - converter.outputs.reject(&:loss?).map(&:external_value).compact.sum
    else
      0.0
    end
  end
  unit_for_calculation "output_of_loss", 'MJ'


  def output_of(*carriers)
    carriers.flatten.map do |c|
      key = c.respond_to?(:key) ? c.key : c
      (key == :loss) ? output_of_loss : output_of_carrier(key)
    end.compact.sum
  end

  def output_of_carrier(carrier)
    c = converter.output(carrier)
    (c and c.external_value) || 0.0
  end

  # Helper method to get all heat outputs (useable_heat, steam_hot_water)
  #
  def output_of_heat_carriers
    fetch(:output_of_heat_carriers) do
      output_of_useable_heat + output_of_steam_hot_water
    end
  end
  unit_for_calculation "output_of_heat_carriers", 'MJ'

  def output_of_heat_and_cooling_carriers
    fetch(:output_of_heat_and_cooling_carriers) do
      output_of_useable_heat + output_of_steam_hot_water + output_of_cooling
    end
  end
  unit_for_calculation "output_of_heat_and_cooling_carriers", 'MJ'


  # Don't use this function before checking if all fossil carriers are
  # included!
  def input_of_fossil_carriers
    fetch(:input_of_fossil_carriers) do
      input_of_coal + input_of_crude_oil + input_of_natural_gas + input_of_diesel + input_of_gasoline + input_of_gas_power_fuelmix
    end
  end
  unit_for_calculation "input_of_fossil_carriers", 'MJ'

  def input_of_ambient_carriers
    fetch(:input_of_ambient_carriers) do
      input_of_ambient_heat + input_of_solar_radiation + input_of_ambient_cold + input_of_wind
    end
  end
  unit_for_calculation "input_of_ambient_carriers", 'MJ'

  def demand_of_carrier(carrier)
    Rails.logger.info('demand_of_* is deprecated. Use output_of_* instead')
    output_of_carrier(carrier)
  end


  def input_of(*carriers)
    carriers.flatten.map do |c|
      key = c.respond_to?(:key) ? c.key : c
      (key == :loss) ? input_of_loss : input_of_carrier(key)
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
    fetch(:electricity_output_efficiency) do
      c = converter.output(:electricity)
      c and c.conversion
    end
  end


end
