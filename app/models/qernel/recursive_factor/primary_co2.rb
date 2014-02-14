module Qernel::RecursiveFactor::PrimaryCo2

  def primary_demand_co2_per_mj_of_carrier(carrier_key)
    factor = recursive_factor(:co2_per_mj_of_carrier_factor, nil, nil, carrier_key)
    (self.demand || 0.0) * factor
  end

  def primary_co2_emission
    fetch(:primary_co2_emission) { primary_demand_with(:co2_per_mj, :co2) }
  end

  # TODO: Add documentation.
  def co2_factor
    1.0 - free_co2_factor
  end

  # Internal: The proportion of the converter's energy which is generated
  # without CO2 emissions.
  #
  # Returns a numeric.
  def free_co2_factor
    query.free_co2_factor || 0.0
  end

  # @return [0.0] if converter is non_energetic_use / has free_co2_factor of 1.0. This ends the recursive_factor.
  # @return [nil] until dead end or primary_energy_demand
  # @return [Float] co2_per_mj of primary_energy_demand carrier
  #
  def co2_per_mj_of_carrier_factor(link, carrier_key, ruby18fix = nil)
    return 0.0 if query.free_co2_factor == 1.0
    return nil if !right_dead_end? or !primary_energy_demand?
    link ||= output_links.first

    if link and carrier = link.carrier and link.carrier.key == carrier_key
      return 0.0 if query.free_co2_factor.nil? or carrier.co2_conversion_per_mj.nil?
      carrier.co2_per_mj - (query.free_co2_factor * carrier.co2_conversion_per_mj)
    else
      0.0
    end
  end

  # @return [0.0] if converter is non_energetic_use / has free_co2_factor of 1.0. This ends the recursive_factor.
  # @return [nil] until dead end or primary_energy_demand
  # @return [Float] co2_per_mj of primary_energy_demand carrier
  #
  def co2_per_mj_factor(link,ruby18fix = nil)
    return nil if !right_dead_end? or !primary_energy_demand?
    link ||= output_links.first

    carrier = link.nil? ? output_carriers.reject(&:loss?).first : link.carrier
    puts "no carrier for #{self.name}" if carrier.nil?

    return 0.0 if free_co2_factor == 1.0 or carrier.co2_conversion_per_mj.nil?
    co2_ex_free = carrier.co2_per_mj - (free_co2_factor * carrier.co2_conversion_per_mj)
    (primary_energy_demand? and carrier.co2_conversion_per_mj) ? co2_ex_free : 0.0
  end

end
