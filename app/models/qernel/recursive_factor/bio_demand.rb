# frozen_string_literal: true

# Recursively computes the bio energy demand of a node. This is the amount
# of energy provided by nodes -- including abroad -- which belong to the
# bio_resources_demand group.
module Qernel::RecursiveFactor::BioDemand
  # Public: Calculates the primary bio demand including from sources abroad.
  #
  # This is the same as primary_demand_including_abroad, except instead of
  # terminating at `primary_energy_demand`, it instead terminates at the
  # `bio_resources_demand` group.
  #
  # Returns a numeric.
  def demand_of_bio_resources_including_abroad
    fetch(:demand_of_bio_resources) do
      (demand || 0.0) * recursive_factor(
        :demand_of_bio_resources_including_abroad_factor, include_abroad: true
      )
    end
  end

  # Public: Calculates the primary bio demand, including sources from abroad, of
  # energy of the named carrier.
  #
  # This is the same as `primary_demand_of`, but terminating at the
  # `bio_resources_demand` group instead of `primary_energy_demand`.
  #
  # Returns a numeric.
  def demand_of_bio_resources_including_abroad_of(*carriers)
    carriers.uniq!

    carriers.sum do |carrier|
      demand_of_bio_resources_including_abroad_of_carrier(carrier)
    end
  end

  private

  def demand_of_bio_resources_including_abroad_factor(_edge)
    return nil unless right_dead_end? || bio_resources_demand?
    factor_for_primary_demand(:bio_resources_demand?)
  end

  # Internal: Triggers the recursive factor calculation of the bio resources
  # demand from the current node.
  #
  # Returns a numeric.
  def demand_of_bio_resources_including_abroad_of_carrier(carrier_key)
    return 0.0 if !demand || demand.zero?

    demand * recursive_factor(
      :demand_of_bio_resources_including_abroad_of_carrier_factor,
      nil, # node_share_method
      nil, # edge
      carrier_key
    )
  end

  # Public: Computes the bio resources factor of the current node for the given
  # carrier key. Only primary bio demand of the given carrier is included.
  #
  # Returns a numeric.
  def demand_of_bio_resources_including_abroad_of_carrier_factor(
    edge,
    carrier_key
  )
    return nil unless right_dead_end? || bio_resources_demand?

    edge ||= output_edges.first

    if edge && edge.carrier.key == carrier_key
      factor_for_primary_demand(:bio_resources_demand?)
    else
      0.0
    end
  end
end
