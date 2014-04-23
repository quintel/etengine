module Qernel::RecursiveFactor::FinalDemand


  def final_demand
    fetch(:final_demand) do
      (self.demand || 0.0) * recursive_factor(:final_demand_factor)
    end
  end

  def final_demand_of(*carriers)
    carriers.flatten.map do |c|
      key = c.respond_to?(:key) ? c.key : c
      final_demand_of_carrier(key)
    end.compact.sum
  end

  def final_demand_of_carrier(carrier_key)
    factor = recursive_factor(:final_demand_factor_of_carrier, nil, nil, carrier_key)
    (self.demand || 0.0) * factor
  end

  def final_demand_factor_of_carrier(link, carrier_key)
    link ||= output_links.first # in case we query a left-most converter

    if link && final_demand_group?
      link.carrier.key == carrier_key ? 1.0 : 0.0
    else
      nil
    end
  end

  def final_demand_factor(link,ruby18fix = nil)
    if    final_demand_group?  then 1.0
    elsif right_dead_end?    then 0.0
    else                          nil
    end
  end
end
