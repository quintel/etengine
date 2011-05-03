class Qernel::ConverterApi

  ##
  # used for slider minim
  #
  def min_supply_for_plant
    factor = (1.0 - (Current.scenario.years.to_f / (technical_lifetime || 0.0)))
    factor = 0.0 if factor < 0.0
    factor * converter.query.output_of_electricity
  end

  ##
  # used for slider minim
  #
  def min_amount_of_plants
    factor = (1.0 - (Current.scenario.years.to_f / (technical_lifetime || 0.0)))
    factor = 0.0 if factor < 0.0
    factor * (number_of_plants || 0.0)
  end

  ##
  # used for slider minim
  #
  # @deprecated (2010-06-10): Use following GQL query: DIVIDE(Q(electricity_production),V(...;typical_production))
  # It is deprecated because it is dependent on a Graph-query
  #
  def max_amount_of_plants
    raise "max_amount_of_plants is deprecated."
    el = converter.graph.query.electricity_production
    el / (typical_production || 0.0)
  end
  
  def min_mw_for_plant
    factor = (1.0 - (Current.scenario.years.to_f / (technical_lifetime || 0.0)))
    factor = 0.0 if factor < 0.0
    (factor * converter.query.output_of_electricity) / SECS_PER_YEAR 
  end
  
  def min_heat_mw_for_plant
    factor = (1.0 - (Current.scenario.years.to_f / (technical_lifetime || 0.0)))
    factor = 0.0 if factor < 0.0
    (factor * converter.query.useful_heat_output) / SECS_PER_YEAR 
  end

end
