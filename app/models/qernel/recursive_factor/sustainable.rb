module Qernel::RecursiveFactor::Sustainable
  # Primary demand of sustainable sources. Uses the Carrier#sustainable
  # attribute.
  def primary_demand_of_sustainable
    fetch(:primary_demand_of_sustainable) do
      primary_demand * sustainability_share
    end
  end

  # Primary demand of fossil sources.
  #
  # i.e. (primary_demand - primary_demand_of_sustainable)
  def primary_demand_of_fossil
    fetch(:primary_demand_of_fossil) do
      primary_demand * (1.0 - sustainability_share)
    end
  end

  # The share of sustainable energy. It is the (recursive) sum of the
  #  sustainable shares of its parents (nodes to the right).
  #
  # A.sustainability_share == 0.4*0.85 + 0.6 * 1.0
  def sustainability_share
    fetch(:sustainability_share, false) do
      recursive_factor_without_losses(:sustainability_share_factor, value_type: :value)
    end
  end

  def sustainability_share_factor(edge)
    return nil unless domestic_dead_end? || primary_energy_demand?

    # Called sustainability_share directly on a domestic or primary node.
    return query.dataset_get(:sustainability_share) unless edge

    # If the node has a sustainability share which has been explicitly
    # set (through research data or a graph plugin), use that in preference to
    # the carrier sustainability.
    share = query.dataset_get(:sustainability_share) || edge.carrier.sustainable

    share ||
      raise("Missing sustainability_share or carriers with sustainable value for #{key} node")
  end

  # Total amount of energy that are losses
  #
  # @return [Float]
  def total_losses
    output(:loss).try(:external_value)
  end

  def infinite?
    slots.map(&:carrier).any?(&:infinite)
  end
end
