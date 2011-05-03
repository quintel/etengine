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
  
  #RD: Does this belong here?
  # SB: Yes. kinda
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