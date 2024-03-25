module Qernel::RecursiveFactor::WeightedCarrier
  # Carrier Cost can depend on the share of other carriers flowing into it.
  # For example, gas price is dependent on the mix of greengas and natural gas.
  #
  # A.carrier_cost_per_mj == 0.4*0.85 + 0.6 * 1.0
  def weighted_carrier_cost_per_mj
    fetch(:weighted_carrier_cost_per_mj) do
      recursive_factor_without_losses(:weighted_carrier_cost_per_mj_factor)
    end
  end

  def weighted_carrier_cost_per_mj_factor(edge)
    return unless edge

    # Carriers with no or zero intrinsic costs are not counted in this calculation.

    edge.carrier.cost_per_mj if edge.carrier.cost_per_mj || domestic_dead_end?

    # Else: continue traversing right.
  end

  # Same as weighted_carrier_cost_per_mj but for co2
  def weighted_carrier_co2_per_mj
    fetch(:weighted_carrier_co2_per_mj) do
      recursive_factor_without_losses(:weighted_carrier_co2_per_mj_factor)
    end
  end

  def weighted_carrier_co2_per_mj_factor(edge)
    return unless edge

    # Carriers with no or zero intrinsic CO2 are not counted in this calculation.

    if edge.carrier.co2_conversion_per_mj || domestic_dead_end?
      edge.carrier.co2_conversion_per_mj
    end

    # Else: continue traversing right.
  end

  # Same as weighted_carrier_cost_per_mj but for co2 potential biogenic capture
  def weighted_carrier_potential_co2_per_mj
    fetch(:weighted_carrier_potential_co2_per_mj) do
      recursive_factor_without_losses(:weighted_carrier_potential_co2_per_mj_factor)
    end
  end

  def weighted_carrier_potential_co2_per_mj_factor(edge)
    return unless edge

    # Carriers with no or zero intrinsic biogenic CO2 capture potential are not
    # counted in this calculation.

    if edge.carrier.potential_co2_conversion_per_mj || domestic_dead_end?
      edge.carrier.potential_co2_conversion_per_mj
    end

    # Else: continue traversing right.
  end
end
