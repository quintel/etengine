module Qernel::WouterDance::FinalDemand

  def final_demand
    dataset_fetch(:final_demand_memoized) do
      (self.demand || 0.0) * wouter_dance(:final_demand_factor)
    end
  end

  def final_demand_of_carrier(carrier_key)
    factor = wouter_dance(:final_demand_factor_of_carrier, nil, nil, carrier_key)
    (self.demand || 0.0) * factor
  end


  def final_demand_factor(link,*args)
    return 1.0 if final_demand_cbs?
    return 0.0 if right_dead_end?
    nil
  end
  
  def final_demand_factor_of_carrier(link, carrier_key, *args)
  end

end
