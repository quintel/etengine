module Qernel::RecursiveFactor::PrimaryDemand
  # Calculates the primary energy demand. It recursively iterates through all
  # the child links.
  #
  # It uses primary_energy_demand? to determine if primary or not.
  def primary_demand
    fetch(:primary_demand) do
      (demand || 0.0) * recursive_factor(:primary_demand_factor)
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

  def primary_demand_with(factor_method, converter_share_method = nil)
    factor =
      if converter_share_method
        recursive_factor(
          "#{factor_method}_factor",
          "#{converter_share_method}_factor"
        )
      else
        recursive_factor("#{factor_method}_factor")
      end

    (demand || 0.0) * factor
  end

  def primary_demand_factor(link)
    return nil unless right_dead_end?

    # We return nil when we want to continue traversing. So typically this is
    # until we hit a dead end. Alternatively (for final_demand) we could stop
    # when we hit a converter that is final_demand_group?
    factor_for_primary_demand(link)
  end

  def primary_demand_factor_of_carrier(link, carrier_key)
    return nil if !right_dead_end? || !primary_energy_demand?

    link ||= output_links.first

    if link && link.carrier.key == carrier_key
      factor_for_primary_demand(link)
    else
      0.0
    end
  end

  def factor_for_primary_demand(link)
    # Example of a case when a link is not assigned (and therefore needs to be
    # assigned in order to check if its imported_electricity):
    #
    # When you get the primary_demand of the group primary_energy_demand, you
    # already  start at the right dead end and don't jump throught links.
    link ||= output_links.first

    # If a converter has infinite ressources (such as wind, solar/sun), we
    # take the output of energy (1 - losses).
    if infinite? && primary_energy_demand?
      (1 - loss_output_conversion)

    elsif primary_energy_demand? # Normal case.
      1.0
    else
      0.0
    end
  end
end
