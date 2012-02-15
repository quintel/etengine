module Qernel::WouterDance::PrimaryDemand



  # Calculates the primary energy demand. It recursively iterates through all the child links.
  # primary_demand: demand * SUM(links)[ link_share * 1/(1-share_of_loss) * primary_demand_link]
  # It uses primary_energy_demand? to determine if primary or not.
  #
  def primary_demand    
    dataset_fetch(:primary_demand_memoized) do
      demand = self.demand
      if demand.nil? || demand == 0.0
        0.0
      else
        demand * wouter_dance(:primary_demand_factor)
      end
    end
  end


  def primary_demand_factor_of_carrier(link, carrier_key, *args)
    return nil if !right_dead_end? or !primary_energy_demand?
    link ||= output_links.first

    if link and link.carrier.key == carrier_key
      factor_for_primary_demand(link)
    else
      0.0
    end
  end

  def factor_for_primary_demand(link)    
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


  # The share of sustainable energy. It is the (recursive) sum of the
  #  sustainable shares of its parents (nodes to the right).
  #
  # A.sustainability_share == 0.4*0.85 + 0.6 * 1.0
  #
  def sustainability_share
    dataset_fetch(:sustainability_share_factor_memoized) do
      wouter_dance_without_losses(:sustainability_share_factor)
    end
  end

  def sustainability_share_factor(link, *args)
    if right_dead_end? and link
      link.carrier.sustainable
    else
      nil
    end
  end


  # Primary demand of only a specific carrier.
  #
  def primary_demand_of_carrier(carrier_key)
    factor = wouter_dance(:primary_demand_factor_of_carrier, nil, nil, carrier_key)
    (self.demand || 0.0) * factor
  end


  # Primary demand of sustainable sources. Uses the Carrier#sustainable attribute
  #
  def primary_demand_of_sustainable
    dataset_fetch(:primary_demand_of_sustainable_memoized) do
      (self.demand || 0.0) * (wouter_dance(:sustainable_factor))
    end
  end

  # Primary demand of fossil sources. (primary_demand - primary_demand_of_sustainable)
  #
  def primary_demand_of_fossil
    dataset_fetch(:primary_demand_of_fossil_memoized) do
      self.primary_demand - (wouter_dance(:sustainable_factor)) * (self.demand || 0.0)
    end
  end


  def infinite_demand
    infinte_demand_factor ||= wouter_dance(:infinte_demand_factor)
    (self.demand || 0.0) * infinte_demand_factor
  end
  
  def infinte_demand_factor(link, *args)
    return nil if !right_dead_end?
    (infinite? and primary_energy_demand?) ? (1 - loss_output_conversion) : 0.0
  end


  # We return nil when we want to continue traversing. So typically this is until
  # we hit a dead end. Alternatively (for final_demand) we could stop when we hit
  # a converter that is final_demand_cbs?
  def primary_demand_factor(link,*args)
    return nil if !right_dead_end?
    # Example of a case when a link is not assigned (and therefore needs to be assigned
    # in order to check if its imported_electricity):
    # When you get the primary_demand of the group primary_energy_demand, you already
    # start at the right dead end and don't jump throught links.
    link ||= output_links.first

    factor_for_primary_demand(link)
  end

  #def sustainable_factor(link,*args)
  #  return nil unless right_dead_end?
  #  link ||= output_links.first
  #
  #    link.nil? ? 0.0 : link.carrier.sustainable
  # end

  def sustainable_factor(link,*args)
    return nil if !right_dead_end?
    link ||= output_links.first

    if infinite? and primary_energy_demand?
      (1 - loss_output_conversion)
    elsif primary_energy_demand? and link and link.carrier.sustainable
      link.carrier.sustainable
    else
      0.0
    end
  end


end
