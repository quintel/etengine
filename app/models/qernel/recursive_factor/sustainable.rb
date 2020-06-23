module Qernel::RecursiveFactor::Sustainable
  # Primary demand of sustainable sources. Uses the Carrier#sustainable
  # attribute.
  def primary_demand_of_sustainable
    fetch(:primary_demand_of_sustainable) do
      (demand || 0.0) * recursive_factor(:sustainable_factor)
    end
  end

  # Primary demand of fossil sources.
  #
  # i.e. (primary_demand - primary_demand_of_sustainable)
  def primary_demand_of_fossil
    fetch(:primary_demand_of_fossil) do
      primary_demand - recursive_factor(:sustainable_factor) * (demand || 0.0)
    end
  end

  # The share of sustainable energy. It is the (recursive) sum of the
  #  sustainable shares of its parents (nodes to the right).
  #
  # A.sustainability_share == 0.4*0.85 + 0.6 * 1.0
  def sustainability_share
    fetch(:sustainability_share_calc, false) do
      recursive_factor_without_losses(:sustainability_share_factor)
    end
  end

  def sustainability_share_factor(edge)
    return nil unless (domestic_dead_end? || primary_energy_demand?) && edge

    # If the node has a sustainability share which has been explicitly
    # set (through research data or a graph plugin), use that in preference to
    # the carrier sustainability.
    share = query.dataset_get(:sustainability_share) || edge.carrier.sustainable

    if share && edge.input.conversion > 1.0
      # Adjust for slots with a greater than 1.0 conversion, which typically
      # indicates input loss in storage (such as P2P batteries).
      share / edge.input.conversion
    else
      share
    end
  end

  def sustainable_factor(edge)
    return 0.0 if domestic_dead_end? && !primary_energy_demand?
    return nil unless primary_energy_demand?

    edge ||= output_edges.first

    if query.dataset_get(:sustainability_share)
      query.dataset_get(:sustainability_share)
    elsif infinite?
      (1 - loss_output_conversion)
    elsif edge && edge.carrier.sustainable
      edge.carrier.sustainable
    else
      0.0
    end
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
