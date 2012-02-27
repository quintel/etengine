class Qernel::ConverterApi

  def primary_demand_of_fossil
    converter.primary_demand_of_fossil
  end

  def primary_demand_of_sustainable
    converter.primary_demand_of_sustainable
  end

  def sustainability_share
    converter.sustainability_share
  end

  # Inverse of sustainability_share
  # https://github.com/dennisschoenmakers/etengine/issues/272
  def non_renewable_share
    1.0 - (sustainability_share || 0.0)
  end

  def weighted_carrier_cost_per_mj
    converter.weighted_carrier_cost_per_mj
  end

  def weighted_carrier_co2_per_mj
    converter.weighted_carrier_co2_per_mj
  end


  register_calculation_method [
    :weighted_carrier_co2_per_mj,
    :weighted_carrier_cost_per_mj,
    :sustainability_share,
    :primary_demand_of_sustainable,
    :primary_demand_of_fossil
  ]
end