module Qernel::RecursiveFactor::WeightedCarrier
  # Carrier Cost can depend on the share of other carriers flowing into it.
  # For example, gas price is dependent on the mix of greengas and natural gas.
  #
  # A.carrier_cost_per_mj == 0.4*0.85 + 0.6 * 1.0
  def weighted_carrier_cost_per_mj
    fetch(:weighted_carrier_cost_per_mj) do
      recursive_factor_without_losses(:weighted_carrier_cost_per_mj_factor) *
        converter_api.costable_energy_factor
    end
  end

  def weighted_carrier_cost_per_mj_factor(link)
    # because electricity and steam_hot_water are calculated seperately
    # these are excluded from this calculation
    return unless link

    if link.carrier.electricity? || link.carrier.steam_hot_water?
      0.0
    elsif link.carrier.cost_per_mj || domestic_dead_end?
      link.carrier.cost_per_mj
    end

    # Else: continue traversing right.
  end

  # Same as weighted_carrier_cost_per_mj but for co2
  def weighted_carrier_co2_per_mj
    fetch(:weighted_carrier_co2_per_mj) do
      recursive_factor_without_losses(:weighted_carrier_co2_per_mj_factor)
    end
  end

  def weighted_carrier_co2_per_mj_factor(link)
    return unless link

    # Electricity and steam_hot_water have no intrinsic CO2 and are therefore
    # excluded from this calculation.

    if link.carrier.co2_conversion_per_mj || domestic_dead_end?
      link.carrier.co2_conversion_per_mj
    end

    # Else: continue traversing right.
  end
end
