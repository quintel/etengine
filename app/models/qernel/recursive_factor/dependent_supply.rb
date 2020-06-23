# Dependent supply is the amount of energy which must be generated earlier in
# the supply chain in order to satisfy the demand of a node.
#
# For example, you might look at an air-conditioning node for business premises
# and want to know how much coal is required to supply the power plants which
# in turn supply the electricity. This is not possible by looking at the cooling
# node's slots alone, because the coal is not input to the air-conditioner, but
# is transformed much earlier in the graph.
module Qernel::RecursiveFactor::DependentSupply
  # Public: Calculates how much energy must be generated earlier in the graph -
  # matching the given +carriers+ keys - in order to fulfil demand of this
  # node.
  #
  # You may supply one or more carrier keys. If you want to determine the
  # dependent supply of multiple, related carriers, you MUST always call this
  # method once with all of the carrier keys, rather than calling it once PER
  # carrier and them summing the result. This is because multiple separate calls
  # may traverse the same edges, causing energy to be counted many times.
  #
  # A good example of this is with gas, where you may specifiy:
  #
  #   dependent_supply_of_carriers(:network_gas, :natural_gas)
  #
  # If you were to do this:
  #
  #   SUM(
  #     dependent_supply_of_carriers(:network_gas),
  #     dependent_supply_of_carriers(:natural_gas))
  #
  # ... the natural gas which SUPPLIES the network gas nodes would be
  # counted twice.
  #
  # Returns a numeric.
  def dependent_supply_of_carriers(*carriers)
    if demand && !demand.zero?
      demand * recursive_factor(
        :dependent_supply_factor_of_carriers, nil, nil, carriers
      )
    else
      0.0
    end
  end

  alias_method :dependent_supply_of_carrier, :dependent_supply_of_carriers

  # Public: Calculates what proportion of a node's demand can be attributed to
  # the given +carrier_key+. Normally you can achieve this by looking at the
  # slot share, but this is of no use if you want to detmine how much of a
  # carrier was used earlier in the graph.
  #
  # For example, you may want to know how much "green_gas" is used in a heating
  # node, but the node only receives "network_gas", the "green_gas" having
  # been mixed with "natural_gas" earlier in the supply chain. Recursive factor
  # will look to the supply-side of the node and find the green gas which
  # ends up being used for heating.
  #
  # There are two phases to the carrier dependent supply calculation. Phase 1
  # involves recursively traversing each input path until it either finds edges
  # of the desired carrier, or reaches the dependent supply nodes which have no
  # incoming edges. Once a edge has been found of the desired carrier on the
  # path, "phase 2" begins in which we continue traversing to the right until
  # there are no more edges of that carrier, at which point the dependent supply
  # factor is calculated.
  #
  # See: https://github.com/quintel/etengine/issues/647
  #
  # edge     - The edge whose dependent supply is to be calculated.
  # carriers - The carrier for which you want to calculate the dependent supply.
  #
  # Returns a numeric.
  def dependent_supply_factor_of_carriers(edge, carriers)
    return nil unless edge

    # Phase 1; we have yet to find a edge of the desired carrier; continue
    # traversing until we find one, or run out of edges.
    return nil unless carriers.include?(edge.carrier.key)

    # Phase 2; we have found a edge of the desired carrier.
    dead_end = edge.rgt_node.inputs.none? do |slot|
      carriers.include?(slot.carrier.key)
    end

    return unless dead_end || primary_energy_demand?

    # ... the supplier has no more edges of this type, therefore we
    # calculate the dependent supply factor and do not traverse further.
    #
    # If factor_for_primary_demand returns zero, it is simply because the
    # supply node is not in the primary_energy_demand group; however we
    # don't want to ignore the node, but instead use its demand value.
    factor = factor_for_primary_demand
    factor.zero? ? edge.rgt_output.conversion : factor
  end
end # Qernel::RecursiveFactor::DependentDemand
