module Qernel::RecursiveFactor::PrimaryCo2
  def primary_demand_co2_per_mj_of_carrier(carrier_key)
    (demand || 0.0) *
      recursive_factor(:co2_per_mj_of_carrier_factor, nil, nil, carrier_key)
  end

  def primary_co2_emission
    fetch(:primary_co2_emission) do
      primary_demand_with(:co2_per_mj, :co2) - captured_bio_emissions
    end
  end

  # TODO: Add documentation.
  def co2_factor
    1.0 - free_co2_factor
  end

  # Internal: The proportion of the node's energy which is generated
  # without CO2 emissions.

  # Returns a numeric.
  def free_co2_factor
    dataset_get(:free_co2_factor) || 0.0
  end

  # @return [0.0]
  #   if node is non_energetic_use / has free_co2_factor of 1.0.
  #   This ends the recursive_factor.
  # @return [nil]
  #   until dead end or primary_energy_demand
  # @return [Float]
  #   co2_per_mj of primary_energy_demand carrier
  def co2_per_mj_of_carrier_factor(edge, carrier_key)
    return 0.0 if query.free_co2_factor == 1.0

    return nil unless domestic_dead_end? || primary_energy_demand?

    edge ||= output_edges.first

    if edge && (carrier = edge.carrier) && (edge.carrier.key == carrier_key)
      if query.free_co2_factor.nil? || carrier.co2_conversion_per_mj.nil?
        0.0
      else
        edge.query.co2_per_mj -
          (query.free_co2_factor * carrier.co2_conversion_per_mj)
      end
    else
      0.0
    end
  end

  # @return [0.0]
  #  if node is non_energetic_use / has free_co2_factor of 1.0.
  #   This ends the recursive_factor.
  # @return [nil]
  #   until dead end or primary_energy_demand
  # @return [Float]
  #   co2_per_mj of primary_energy_demand carrier
  #
  def co2_per_mj_factor(edge)
    return nil unless domestic_dead_end? || primary_energy_demand?

    edge ||= output_edges.first

    carrier = edge.nil? ? output_carriers.reject(&:loss?).first : edge.carrier

    return 0.0 if free_co2_factor == 1.0 || carrier.co2_conversion_per_mj.nil?

    co2_ex_free = edge.query.co2_per_mj -
      (free_co2_factor * carrier.co2_conversion_per_mj)

    @node.primary_energy_demand? && carrier.co2_conversion_per_mj ? co2_ex_free : 0.0
  end

  private

  def captured_bio_emissions
    if free_co2_factor.positive?
      primary_co2_emission_of_bio_carriers * free_co2_factor
    else
      0.0
    end
  end
end
