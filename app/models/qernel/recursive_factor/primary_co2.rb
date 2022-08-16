module Qernel::RecursiveFactor::PrimaryCo2
  def primary_demand_co2_per_mj_of_carrier(carrier_key)
    (demand || 0.0) *
      recursive_factor(:co2_per_mj_of_carrier_factor, nil, nil, carrier_key)
  end

  # Public: Returns the total primary CO2 emissions due to fossil carriers minus any bio emissions
  # captured on this or ancestor nodes.
  #
  # Returns a numeric in kg.
  def primary_co2_emission
    fetch(:primary_co2_emission) do
      primary_co2_emission_of_fossil - inherited_captured_bio_emissions
    end
  end

  # Public: Returns the total primary CO2 emissions due to fossil carriers minus any "free"
  # fossil CO2 (determined by the `free_co2_factor` of any ancestor nodes).
  #
  # Returns a numeric in kg.
  def primary_co2_emission_of_fossil
    fetch(:primary_co2_emission_of_fossil) do
      primary_demand_with(:co2_per_mj, :co2)
    end
  end

  # Public: Returns the total primary CO2 fossil emissions including any "free" CO2 on this or
  # ancestor nodes (determined by the `free_co2_factor`).
  #
  # Returns a numeric in kg.
  def primary_co2_emission_without_capture
    fetch(:primary_co2_emission_without_capture) do
      primary_demand_with(:co2_per_mj_without_capture)
    end
  end

  # Public: Calculates and returns the combined emissions of fossil and bio carriers caused by
  # the node _including_ any captured by CCS or otherwise ignored by the `free_co2_factor`.
  #
  # Returns a numeric in kg.
  def primary_co2_emission_of_bio_and_fossil_without_capture
    primary_co2_emission_without_capture + primary_co2_emission_of_bio_carriers
  end

  # Public: The same as `primary_co2_emission_of_bio_and_fossil_without_capture` but instead returns
  # the factor/share instead of the amount in MJ.
  #
  # Returns a numeric.
  def primary_co2_emission_of_bio_and_fossil_without_capture_factor
    fetch(:primary_co2_emission_of_bio_and_fossil_without_capture_factor) do
      recursive_factor(:co2_per_mj_factor) + recursive_factor(:bio_co2_per_mj_factor)
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
  # Accepts a `co2_free` keyword argument, which defaults to `free_co2_factor`. Normally,
  # calculating the CO2 per MJ should omit any "free" CO2 (such as that which is captured). You may
  # specify a custom value instead, such as when calculating the captured emissions.
  #
  def co2_per_mj_factor(edge, co2_free: free_co2_factor)
    # Normally CO2 is only included on nodes which are a member of the primary energy demand group.
    # In rare cases, we want to exclude a node from being included in the primary demand calculation
    # while opting in to the CO2 calculation. This is done by omitting the node from the PD group
    # and instead adding it to the "include_primary_co2" group.
    force_co2 = domestic_dead_end? && @node.groups.include?(:force_primary_co2)

    return nil unless domestic_dead_end? || primary_energy_demand? || force_co2

    edge ||= output_edges.first

    carrier = edge.nil? ? output_carriers.reject(&:loss?).first : edge.carrier

    return 0.0 if co2_free == 1.0 || carrier.co2_conversion_per_mj.nil?

    co2_ex_free = edge.query.co2_per_mj - (co2_free * carrier.co2_conversion_per_mj)

    if (@node.primary_energy_demand? || force_co2) && carrier.co2_conversion_per_mj
      co2_ex_free
    else
      0.0
    end
  end

  # Internal: Calculates the factor (used by RF) of CO2 emitted by primary demand nodes without
  # regard for the `free_co2_factor` attribute.
  #
  # See primary_co2_emission_without_capture
  #
  # Returns a numeric.
  def co2_per_mj_without_capture_factor(edge)
    co2_per_mj_factor(edge, co2_free: 0.0)
  end
end
