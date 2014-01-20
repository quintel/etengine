class Qernel::ConverterApi

  def demand_of_fossil
    fetch_and_rescue(:demand_of_fossil) do
      converter.input_carriers.map do |carrier|
        if carrier.sustainable and demand = demand_of_carrier(carrier)
          demand * (1 - carrier.sustainable)
        end
      end.compact.sum
    end
  end
  alias_method :output_of_fossil, :demand_of_fossil

  def demand_of_sustainable
    fetch_and_rescue(:demand_of_sustainable) do
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
    fetch_and_rescue(:output_of_heat_carriers) do
      output_of_useable_heat + output_of_steam_hot_water
    end
  end
  unit_for_calculation "output_of_heat_carriers", 'MJ'

  def output_of_heat_and_cooling_carriers
    fetch_and_rescue(:output_of_heat_and_cooling_carriers) do
      output_of_useable_heat + output_of_steam_hot_water + output_of_cooling
    end
  end
  unit_for_calculation "output_of_heat_and_cooling_carriers", 'MJ'


  # Don't use this function before checking if all fossil carriers are
  # included!
  def input_of_fossil_carriers
    fetch_and_rescue(:input_of_fossil_carriers) do
      input_of_coal + input_of_crude_oil + input_of_natural_gas + input_of_diesel + input_of_gasoline + input_of_gas_power_fuelmix
    end
  end
  unit_for_calculation "input_of_fossil_carriers", 'MJ'

  def input_of_ambient_carriers
    fetch_and_rescue(:input_of_ambient_carriers) do
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
    fetch_and_rescue(:electricity_output_efficiency) do
      c = converter.output(:electricity)
      c and c.conversion
    end
  end

  # Public: Takes the merit order load curve, and multiplies each point by the
  # demand of the converter, yielding the load on the converter over time.
  #
  # Returns an array, each value a Numeric representing the converter demand in
  # a one-hour period.
  def demand_curve
    fetch_and_rescue(:demand_curve) do
      dataset = Atlas::Dataset.find(area.area_code)
      mo_info = Atlas::Node.find(key).merit_order

      if mo_info && mo_info.group
        dataset.load_profile(mo_info.group).
          values.map { |point| point * demand }
      else
        [] # This converter does not belong to a merit order group.
      end
    end
  end

  # Public: Given a maximum per-hour load +limit+, determines the proportion of
  # hours where demand exceeds production capacity.
  #
  # For example
  #
  #   converter.loss_of_load_probability(10)
  #   # => 0.05
  #   # This means that 5% of the year, the demand on the node exceeds the
  #   # given production capacity(10MJ).
  #
  # Returns a Float. 0.0 is returned if the converter does not belong to a merit
  # order group.
  def loss_of_load_probability(limit)
    if demand_curve.length > 0
      demand_curve.count { |point| point > limit } / demand_curve.length
    else
      0.0
    end
  end

end
