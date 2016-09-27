module Qernel::RecursiveFactor::WeightedCarrier

  # Carrier Cost can depend on the share of other carriers flowing
  # into it.
  # E.g. Gas price is dependent on the mix of greengas and natural
  # gas.
  #
  # A.carrier_cost_per_mj == 0.4*0.85 + 0.6 * 1.0
  #
  def weighted_carrier_cost_per_mj
    fetch(:weighted_carrier_cost_per_mj) do
      recursive_factor_without_losses(:weighted_carrier_cost_per_mj_factor)
    end
  end

  def weighted_carrier_cost_per_mj_factor(link)
    # because electricity and steam_hot_water are calculated seperately
    # these are excluded from this calculation
    # old: if right_dead_end? and link
    # new: always 0 for elec and steam_hw
    if link
      if (link.carrier.electricity? || link.carrier.steam_hot_water?)
        0.0
      elsif link.carrier.cost_per_mj || right_dead_end?
        link.carrier.cost_per_mj
      else
        nil # continue to the right
      end
    else
      nil # continue to the right
    end
  end

  # Same as weighted_carrier_cost_per_mj but for co2
  #
  def weighted_carrier_co2_per_mj
    fetch(:weighted_carrier_co2_per_mj) do
      recursive_factor_without_losses(:weighted_carrier_co2_per_mj_factor)
    end
  end

  def weighted_carrier_co2_per_mj_factor(link)
    # because electricity and steam_hot_water have no intrinsic co2
    # these are excluded from this calculation
    if link
      if link.carrier.co2_conversion_per_mj || right_dead_end?
        link.carrier.co2_conversion_per_mj
      else
        nil # continue to the right
      end
    else
      nil # continue to the right
    end
  end

end
