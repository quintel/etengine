
module Qernel::RecursiveFactor::Sustainable


  # Primary demand of sustainable sources. Uses the Carrier#sustainable attribute
  #
  def primary_demand_of_sustainable
    function(:primary_demand_of_sustainable_memoized) do
      (self.demand || 0.0) * (recursive_factor(:sustainable_factor))
    end
  end

  # Primary demand of fossil sources. (primary_demand - primary_demand_of_sustainable)
  #
  def primary_demand_of_fossil
    function(:primary_demand_of_fossil_memoized) do
      self.primary_demand - (recursive_factor(:sustainable_factor)) * (self.demand || 0.0)
    end
  end


  # The share of sustainable energy. It is the (recursive) sum of the
  #  sustainable shares of its parents (nodes to the right).
  #
  # A.sustainability_share == 0.4*0.85 + 0.6 * 1.0
  #
  def sustainability_share
    function(:sustainability_share_factor_memoized) do
      recursive_factor_without_losses(:sustainability_share_factor)
    end
  end

  def sustainability_share_factor(link)
    if right_dead_end? and link
      link.carrier.sustainable
    else
      nil
    end
  end


  def sustainable_factor(link,ruby18fix = nil)
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


  # Total amount of energy that are losses
  #
  # @return [Float]
  #
  def total_losses
    out = self.output(:loss)
    out and out.external_value
  end



  def infinite_demand
    raise "DEPRECATED infinite_demand"
    infinte_demand_factor ||= recursive_factor(:infinte_demand_factor)
    (self.demand || 0.0) * infinte_demand_factor
  end

  def infinite?
    carriers = slots.map {|slot| slot.carrier}.uniq
    !carriers.empty? and carriers.any?{|carrier| carrier.infinite == 1.0}
  end

  def infinte_demand_factor(link,ruby18fix = nil)
    return nil if !right_dead_end?
    (infinite? and primary_energy_demand?) ? (1 - loss_output_conversion) : 0.0
  end
end