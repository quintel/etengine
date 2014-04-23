module Qernel::RecursiveFactor::PrimaryDemand


  # Calculates the primary energy demand. It recursively iterates through all the child links.
  #
  # primary_demand: demand * SUM(links)[ link_share * 1/(1-share_of_loss) * primary_demand_link]
  #
  # It uses primary_energy_demand? to determine if primary or not.
  #
  def primary_demand
    fetch(:primary_demand) do
      primary_demand_share = recursive_factor(:primary_demand_factor)
      (self.demand || 0.0) * (primary_demand_share)
    end
  end

  def primary_demand_of(*carriers)
    carriers.flatten.map do |c|
      key = c.respond_to?(:key) ? c.key : c
      primary_demand_of_carrier(key)
    end.compact.sum
  end

  def primary_demand_of_carrier(carrier_key)
     if demand && ! demand.zero?
       demand * recursive_factor(
         :primary_demand_factor_of_carrier, nil, nil, carrier_key)
     else
       0.0
     end
  end

  def primary_demand_with(factor_method, converter_share_method = nil)
    if converter_share_method
      w = recursive_factor("#{factor_method}_factor", "#{converter_share_method}_factor")
    else
      w = recursive_factor("#{factor_method}_factor")
    end
    d = (self.demand || 0.0)
    w * d
  end


  def primary_demand_factor(link,ruby18fix = nil)
    return nil if !right_dead_end? # or !primary_energy_demand?
    # We return nil when we want to continue traversing. So typically this is until
    # we hit a dead end. Alternatively (for final_demand) we could stop when we hit
    # a converter that is final_demand_group?
    factor_for_primary_demand(link)
  end

  def primary_demand_factor_of_carrier(link, carrier_key, ruby18fix = nil)
    return nil if !right_dead_end? or !primary_energy_demand?
    link ||= output_links.first

    if link and link.carrier.key == carrier_key
      factor_for_primary_demand(link)
    else
      0.0
    end
  end

  def factor_for_primary_demand(link)
    # Example of a case when a link is not assigned (and therefore needs to be assigned
    # in order to check if its imported_electricity):
    # When you get the primary_demand of the group primary_energy_demand, you already
    # start at the right dead end and don't jump throught links.
    link ||= output_links.first

    # If a converter has infinite ressources (such as wind, solar/sun), we
    # take the output of energy (1 - losses).
    if infinite? and primary_energy_demand?
      (1 - loss_output_conversion)

    # Special case is imported electricity, if we import, somebody else has
    # to produce that electricity from primary energy. To take that into account
    # we add a higher factor for imported_electricity.
    elsif primary_energy_demand? and link and link.carrier.key === :imported_electricity
      # if export should be 1, if its import should be 1.82
      if demand > 0.0 # if demand greater then 0.0 electricity is imported
        graph.area.import_electricity_primary_demand_factor
      else # energy gets exported.
        graph.area.export_electricity_primary_demand_factor
      end

    elsif primary_energy_demand? # Normal case.
      1.0
    # ignore this converter if it is a dead end but not a primary_energy_demand.
    # for example some environment converters.
    else
      0.0
    end
  end

end
