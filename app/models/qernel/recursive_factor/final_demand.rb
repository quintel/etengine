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
    link ||= output_links.first # in case we query a left-most node

    return nil unless final_demand_group?

    if link
      link.carrier.key == carrier_key ? 1.0 : 0.0
    else
      # Left-most node with no outputs may be a member of the final demand
      # group. Look for an input matching the carrier, and use its conversion.
      input(carrier_key).try(:conversion) || 0.0
    end
  end

  def final_demand_factor(_link)
    if final_demand_group?
      1.0
    elsif domestic_dead_end?
      0.0
    end
  end
end
