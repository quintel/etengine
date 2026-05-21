# frozen_string_literal: true

module Qernel::RecursiveFactor::DirectEmissions
  # Calculates the direct carbon content per MJ for emissions calculations.
  # This is similar to weighted_carrier_co2_per_mj but handles emissions-specific
  # edge cases, particularly the :emissions_skip_crude_oil_mix group which forces
  # calculation from the weighted mix of inputs rather than using the carrier's
  # intrinsic CO2 value.
  def direct_carbon_content_per_mj
    fetch(:direct_carbon_content_per_mj) do
      recursive_factor_without_losses(:direct_carbon_content_per_mj_factor)
    end
  end


  # Calculates the direct biogenic carbon content per MJ for emissions calculations.
  # This is similar to direct_carbon_content_per_mj but uses potential_co2_conversion_per_mj
  # to track biogenic CO2 that could potentially be captured or released.
  def direct_biogenic_carbon_content_per_mj
    fetch(:direct_biogenic_carbon_content_per_mj) do
      recursive_factor_without_losses(:direct_biogenic_carbon_content_per_mj_factor)
    end
  end

  private

  def direct_biogenic_carbon_content_per_mj_factor(edge)
    return unless edge

    # Edges marked with emissions_skip_crude_oil_mix should calculate their biogenic CO2
    # content from the weighted mix of inputs further back in the graph, rather
    # than using the carrier's intrinsic potential CO2 value. This handles cases where
    # mixed biogenic carriers represent a blend of different biogenic sources.
    if edge.emissions_skip_crude_oil_mix?
      # Continue traversing right to calculate weighted composition
    elsif !edge.carrier.potential_co2_conversion_per_mj.nil? || !edge.carrier.co2_conversion_per_mj.nil? || right_dead_end?
      edge.carrier.potential_co2_conversion_per_mj || 0.0
    end

    # Else: continue traversing right.
  end

  def direct_carbon_content_per_mj_factor(edge)
    return unless edge

    # Edges marked with emissions_skip_crude_oil_mix should calculate their CO2
    # content from the weighted mix of inputs further back in the graph, rather
    # than using the carrier's intrinsic CO2 value. This handles cases where
    # crude oil edges represent a mix of different crude oil sources with varying
    # CO2 intensities (e.g., conventional vs. heavy crude oil).
    if edge.emissions_skip_crude_oil_mix?
      # Continue traversing right to calculate weighted composition
    elsif edge.carrier.co2_conversion_per_mj || right_dead_end?
      edge.carrier.co2_conversion_per_mj
    end

    # Else: continue traversing right.
  end
end
