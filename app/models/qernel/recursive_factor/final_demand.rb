module Qernel::RecursiveFactor::FinalDemand
  def final_demand
    fetch(:final_demand) do
      (demand || 0.0) * recursive_factor(:final_demand_factor)
    end
  end

  def final_demand_of(*carriers)
    carriers.flatten.map do |carrier|
      final_demand_of_carrier(carrier.try(:key) || carrier)
    end.compact.sum
  end

  def final_demand_of_carrier(carrier_key)
    (demand || 0.0) *
      recursive_factor(:final_demand_factor_of_carrier, nil, nil, carrier_key)
  end

  def final_demand_factor_of_carrier(link, carrier_key)
    link ||= output_links.first # in case we query a left-most converter

    if link && final_demand_group?
      link.carrier.key == carrier_key ? 1.0 : 0.0
    end
  end

  def final_demand_factor(_link)
    if final_demand_group?
      1.0
    elsif right_dead_end?
      0.0
    end
  end
end
