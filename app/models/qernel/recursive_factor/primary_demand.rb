module Qernel::RecursiveFactor::PrimaryDemand
  # Calculates the primary energy demand. It recursively iterates through all
  # the child edges.
  #
  # It uses primary_energy_demand? to determine if primary or not.
  def primary_demand
    fetch(:primary_demand) do
      (demand || 0.0) * recursive_factor(:primary_demand_factor)
    end
  end

  # Calculates the primary energy demand, including traversing through
  # nodes which are flagged as "abroad". The normal primary demand
  # calculation terminates at the border between non-abroad and abroad.
  #
  # Returns a numeric.
  def primary_demand_including_abroad
    fetch(:primary_demand_including_abroad) do
      (demand || 0.0) * recursive_factor(
        :primary_demand_including_abroad_factor, include_abroad: true
      )
    end
  end

  def primary_demand_of(*carriers)
    carriers.flatten.map do |carrier|
      primary_demand_of_carrier(carrier.try(:key) || carrier)
    end.compact.sum
  end

  def primary_demand_of_carrier(carrier_key)
    if demand && !demand.zero?
      demand * recursive_factor(
        :primary_demand_factor_of_carrier, nil, nil, carrier_key
      )
    else
      0.0
    end
  end

  def primary_demand_with(factor_method, node_share_method = nil)
    factor =
      if node_share_method
        recursive_factor(
          "#{factor_method}_factor",
          "#{node_share_method}_factor"
        )
      else
        recursive_factor("#{factor_method}_factor")
      end

    (demand || 0.0) * factor
  end

  def primary_demand_factor(_edge)
    factor_for_primary_demand if primary_energy_demand? || domestic_dead_end?
  end

  def primary_demand_including_abroad_factor(_edge)
    if (abroad? && primary_energy_demand?) || right_dead_end?
      factor_for_primary_demand
    end
  end

  def primary_demand_factor_of_carrier(
    edge,
    carrier_key,
    stop_condition = :primary_energy_demand?
  )
    return nil unless primary_energy_demand?

    edge ||= output_edges.first

    if edge && edge.carrier.key == carrier_key
      factor_for_primary_demand(stop_condition)
    else
      0.0
    end
  end

  # Internal: Calculates the primary demand factor of the given edge.
  #
  # edge           - The edge whose primary demand factor is to be calculated.
  # stop_condition - A method to be called on self to determine if the edge has
  #                  any primary energy demand to be included in the
  #                  calculation.
  #
  # Returns a numeric.
  def factor_for_primary_demand(stop_condition = :primary_energy_demand?)
    stop = public_send(stop_condition)

    # If a node has infinite resources (such as wind, solar/sun), we
    # take the output of energy (1 - losses).
    if infinite? && stop
      (1 - loss_output_conversion)
    elsif stop # Normal case.
      1.0
    else
      0.0
    end
  end
end
