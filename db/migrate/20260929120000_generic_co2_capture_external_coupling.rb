require 'etengine/scenario_migration'

# The generic external coupling node for captured CO2 is gone. The CO2 it captured now flows through
# the refineries transformation node: its emissions input holds the CO2, and its captured input sets
# the share of those emissions that is captured. A scenario keeps the CO2 it captured when that
# amount becomes the node's emissions, captured in full.
#
# The removed input lowered direct emissions by the CO2 it captured, while CO2 emitted and captured
# on the refineries node nets to zero. Direct emissions of a migrated scenario therefore rise by the
# captured amount; primary emissions are unaffected.
class GenericCo2CaptureExternalCoupling < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # The removed input, in Mton of captured CO2.
  OLD_KEY = 'external_coupling_industry_external_coupling_node_captured_co2_supply'.freeze

  # The CO2 of the refineries transformation node in Mton, and the share of it that is captured as
  # a percentage.
  EMISSIONS_KEY =
    'external_coupling_energy_chemical_refineries_transformation_external_coupling_node_co2_emissions'.freeze
  CAPTURED_KEY =
    'external_coupling_energy_chemical_refineries_transformation_external_coupling_node_co2_captured'.freeze

  # The coupling both refineries inputs apply under. The removed input applied under ccus instead.
  REFINERIES_COUPLING = 'industry_chemical_refineries'.freeze

  # The maximum of the emissions input per dataset, in Mton: present:Q(direct_emissions_industry_total_ghg).
  # These are the only datasets holding scenarios with a positive value for the removed input.
  MAX_EMISSIONS = {
    'nl2019' => 54.454325771990995,
    'nl2023' => 52.92312764750488
  }.freeze

  def up
    migrate_scenarios do |scenario|
      next unless scenario.user_values.key?(OLD_KEY)

      captured = scenario.user_values[OLD_KEY].to_f

      # A scenario capturing nothing only loses the removed input. One the migration cannot convert
      # keeps it, and is left as it is.
      if captured.positive?
        next unless migratable?(scenario)

        move_captured_co2(scenario, captured)
      end

      scenario.user_values.delete(OLD_KEY)
    end

    print_report('Skipped scenarios of areas without a maximum:', unknown_areas)
    print_report('Skipped scaled scenarios:', scaled_areas)
    print_report('Skipped scenarios already holding refineries CO2 inputs:', refineries_areas)
    print_report('Skipped scenarios without the refineries coupling:', uncoupled_areas)
    print_report('Scenarios capped at the maximum emissions:', capped_areas)
  end

  private

  # The areas the migration passed over or capped, tallied per area code.
  def unknown_areas = @unknown_areas ||= Hash.new(0)
  def scaled_areas = @scaled_areas ||= Hash.new(0)
  def refineries_areas = @refineries_areas ||= Hash.new(0)
  def uncoupled_areas = @uncoupled_areas ||= Hash.new(0)
  def capped_areas = @capped_areas ||= Hash.new(0)

  # The maximum is that of the full-size dataset, which a scaled scenario does not share. Refineries
  # CO2 a scenario already sets is not the migration's to change. Without the refineries coupling,
  # the scenario ignores both refineries inputs.
  def migratable?(scenario)
    if !MAX_EMISSIONS.key?(scenario.area_code)
      unknown_areas[scenario.area_code] += 1
    elsif scenario.scaler
      scaled_areas[scenario.area_code] += 1
    elsif scenario.user_values.key?(EMISSIONS_KEY) || scenario.user_values.key?(CAPTURED_KEY)
      refineries_areas[scenario.area_code] += 1
    elsif scenario.active_couplings.map(&:to_s).exclude?(REFINERIES_COUPLING)
      uncoupled_areas[scenario.area_code] += 1
    else
      return true
    end

    false
  end

  # Sets the captured CO2 as the emissions of the refineries node, all of which is captured.
  def move_captured_co2(scenario, captured)
    max = MAX_EMISSIONS[scenario.area_code]

    if captured > max
      capped_areas[scenario.area_code] += 1
      captured = max
    end

    # Unrounded, just as the coupled model writes it: No step value applied here
    scenario.user_values[EMISSIONS_KEY] = captured
    scenario.user_values[CAPTURED_KEY] = 100.0
  end
end
