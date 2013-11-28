module Qernel::RecursiveFactor::PrimaryDemand


  # Calculates the primary energy demand. It recursively iterates through all the child links.
  #
  # primary_demand: demand * SUM(links)[ link_share * 1/(1-share_of_loss) * primary_demand_link]
  #
  # It uses primary_energy_demand? to determine if primary or not.
  #
  def primary_demand
    fetch_and_rescue(:primary_demand) do
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

  # Public: Calculates how much energy must be generated earlier in the graph -
  # matching the given +carriers+ keys - in order to fulfil demand of this
  # converter.
  #
  # You may supply one or more carrier keys. If you want to determine the
  # primary demand of multiple, related carriers, you MUST always call this
  # method once with all of the carrier keys, rather than calling it once PER
  # carrier and them summing the result. This is because multiple separate calls
  # may traverse the same edges, causing energy to be counted many times.
  #
  # A good example of this is with gas, where you may specifiy:
  #
  #   primary_demand_of_carriers(:network_gas, :natural_gas)
  #
  # If you were to do this:
  #
  #   SUM(
  #     primary_demand_of_carriers(:network_gas),
  #     primary_demand_of_carriers(:natural_gas))
  #
  # ... the natural gas which SUPPLIES the network gas converters would be
  # counted twice.
  #
  # Returns a numeric.
  def primary_demand_of_carriers(*carriers)
     if demand && ! demand.zero?
       demand * recursive_factor(
         :primary_demand_factor_of_carriers, nil, nil, carriers)
     else
       0.0
     end
  end

  alias_method :primary_demand_of_carrier, :primary_demand_of_carriers

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
    # a converter that is final_demand_cbs?
    factor_for_primary_demand(link)
  end

  # Public: Calculates what proportion of a node's demand can be attributed to
  # the given +carrier_key+. Normally you can achieve this by looking at the
  # slot share, but this is of no use if you want to detmine how much of a
  # carrier was used earlier in the graph.
  #
  # For example, you may want to know how much "green_gas" is used in a heating
  # converter, but the node only receives "network_gas", the "green_gas" having
  # been mixed with "natural_gas" earlier in the supply chain. Recursive factor
  # will look to the supply-side of the converter and find the green gas which
  # ends up being used for heating.
  #
  # There are two phases to the carrier primary demand calculation. Phase 1
  # involves recursively traversing each input path until it either finds links
  # of the desired carrier, or reaches the primary supply nodes which have no
  # incoming links. Once a link has been found of the desired carrier on the
  # path, "phase 2" begins in which we continue traversing to the right until
  # there are no more links of that carrier, at which point the primary demand
  # factor is calculated.
  #
  # See: https://github.com/quintel/etengine/issues/647
  #
  # link        - The link whose primary demand is to be calculated.
  # carrier_key - The carrier name.
  #
  # Returns a numeric.
  def primary_demand_factor_of_carrier(link, carrier_key)
    return nil unless link

    if link.carrier.key == carrier_key
      # Phase 2; we have found a link of the desired carrier.
      if link.rgt_converter.input(carrier_key).nil? || primary_energy_demand?
        # ... the supplier has no more links of this type, therefore we
        # calculate the primary demand factor and do not traverse further.
        #
        # If factor_for_primary_demand returns zero, it is simply because the
        # supply node is not in the primary_energy_demand group; however we
        # don't want to ignore the node, but instead use its demand value.
        factor = factor_for_primary_demand(link)
        factor.zero? ? 1.0 : factor
      else
        # There are more +carrier_key+ links to be traversed...
        nil
      end
    else
      # Phase 1; we have yet to find a link of the desired carrier; continue
      # traversing until we find one, or run out of links.
      nil
    end
  end
  def primary_demand_factor_of_carriers(link, carriers)
    return nil unless link

    if carriers.include?(link.carrier.key)
      # Phase 2; we have found a link of the desired carrier.
      if link.rgt_converter.inputs.none? { |slot| carriers.include?(slot.carrier.key) } || primary_energy_demand?
        # ... the supplier has no more links of this type, therefore we
        # calculate the primary demand factor and do not traverse further.
        #
        # If factor_for_primary_demand returns zero, it is simply because the
        # supply node is not in the primary_energy_demand group; however we
        # don't want to ignore the node, but instead use its demand value.
        factor = factor_for_primary_demand(link)
        factor.zero? ? 1.0 : factor
      else
        # There are more +carrier_key+ links to be traversed...
        nil
      end
    else
      # Phase 1; we have yet to find a link of the desired carrier; continue
      # traversing until we find one, or run out of links.
      nil
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
