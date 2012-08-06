module Qernel::RecursiveFactor::PrimaryCo2

  def primary_demand_co2_per_mj_of_carrier(carrier_key)
    factor = recursive_factor(:co2_per_mj_of_carrier_factor, nil, nil, carrier_key)
    (self.demand || 0.0) * factor
  end

  def primary_co2_emission
    function(:primary_co2_emission) do
      primary_demand_with(:co2_per_mj, :co2_free)
    end
  end


  def co2_free_factor
    (1.0 - (query.co2_free || 0.0))
  end

  # @return [0.0] if converter is non_energetic_use / has co2_free of 1.0. This ends the recursive_factor.
  # @return [nil] until dead end or primary_energy_demand
  # @return [Float] co2_per_mj of primary_energy_demand carrier
  #
  def co2_per_mj_of_carrier_factor(link, carrier_key, ruby18fix = nil)
    return 0.0 if query.co2_free == 1.0
    return nil if !right_dead_end? or !primary_energy_demand?
    link ||= output_links.first

    if link and carrier = link.carrier and link.carrier.key == carrier_key
      return 0.0 if query.co2_free.nil? or carrier.co2_conversion_per_mj.nil?
      carrier.co2_per_mj - (query.co2_free * carrier.co2_conversion_per_mj)
    else
      0.0
    end
  end

  # @return [0.0] if converter is non_energetic_use / has co2_free of 1.0. This ends the recursive_factor.
  # @return [nil] until dead end or primary_energy_demand
  # @return [Float] co2_per_mj of primary_energy_demand carrier
  #
  def co2_per_mj_factor(link,ruby18fix = nil)
    return nil if !right_dead_end? or !primary_energy_demand?
    link ||= output_links.first

    carrier = link.nil? ? output_carriers.reject(&:loss?).first : link.carrier
    puts "no carrier for #{self.name}" if carrier.nil?

    return 0.0 if query.co2_free.nil? or carrier.co2_conversion_per_mj.nil?
    co2_ex_free = carrier.co2_per_mj - (query.co2_free * carrier.co2_conversion_per_mj)
    (primary_energy_demand? and carrier.co2_conversion_per_mj) ? co2_ex_free : 0.0
  end

end
