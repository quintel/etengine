class Qernel::ConverterApi

  def max_demand_recursive
    converter.max_demand_recursive!
  end
  unit_for_calculation "max_demand_recursive", 'MJ'

  def primary_demand_of_fossil
    converter.primary_demand_of_fossil
  end
  unit_for_calculation "primary_demand_of_fossil", 'MJ'

  def primary_demand_of_sustainable
    converter.primary_demand_of_sustainable
  end
  unit_for_calculation "primary_demand_of_sustainable", 'MJ'

  def sustainability_share
    converter.sustainability_share
  end
  unit_for_calculation "primary_demand_of_sustainable", 'factor'

  # Inverse of sustainability_share
  # https://github.com/dennisschoenmakers/etengine/issues/272
  def non_renewable_share
    1.0 - (sustainability_share || 0.0)
  end
  unit_for_calculation "non_renewable_share", 'factor'

  def weighted_carrier_cost_per_mj
    converter.weighted_carrier_cost_per_mj
  end
  unit_for_calculation "weighted_carrier_cost_per_mj", 'euro'

  def weighted_carrier_co2_per_mj
    converter.weighted_carrier_co2_per_mj
  end
  unit_for_calculation "weighted_carrier_co2_per_mj", 'kg'

end