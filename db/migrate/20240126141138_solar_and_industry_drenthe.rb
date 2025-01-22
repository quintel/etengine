require 'etengine/scenario_migration'

class SolarAndIndustryDrenthe < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  # Slider names for the solar thermal part of the migration
  SOLAR_THERMAL = %w[
    households_water_heater_solar_thermal_share
  ].freeze

  # Slider names and constants for the solar part of the migration
  SOLAR_HH = {
    'households_solar_pv_solar_radiation_market_penetration' => 'capacity_of_households_solar_pv_solar_radiation'
  }.freeze

  SOLAR_B = {
    'buildings_solar_pv_solar_radiation_market_penetration' => 'capacity_of_buildings_solar_pv_solar_radiation'
  }.freeze

  LAND_USE_PER_UNIT_SOLAR = 1.6000000000000001e-06
  ELEC_OUTPUT_CAP_SOLAR = 0.000272

  # Slider names for the industry efficiency parts of the migration
  INDUSTRY_EFF = %w[
    industry_useful_demand_for_other_ict_efficiency
    industry_useful_demand_for_chemical_fertilizers_electricity_efficiency
    industry_useful_demand_for_chemical_fertilizers_useable_heat_efficiency
    industry_useful_demand_for_chemical_refineries_electricity_efficiency
    industry_useful_demand_for_chemical_refineries_useable_heat_efficiency
    industry_other_metals_process_electricity_efficiency
    industry_other_metals_process_heat_useable_heat_efficiency
  ].freeze

  INDUSTRY_EFF_NO_NEGATIVE = %w[
    industry_useful_demand_for_chemical_other_electricity_efficiency
    industry_useful_demand_for_chemical_other_useable_heat_efficiency
  ].freeze

  INDUSTRY_EFF_SPLIT_INPUTS = {
    'industry_useful_demand_for_other_food_efficiency' => %w[
      industry_useful_demand_for_other_food_electricity_efficiency
      industry_useful_demand_for_other_food_useable_heat_efficiency
    ],
    'industry_useful_demand_for_other_paper_efficiency' => %w[
      industry_useful_demand_for_other_paper_electricity_efficiency
      industry_useful_demand_for_other_paper_useable_heat_efficiency
    ]
  }.freeze

  # Let's migrate!
  def up
    migrate_scenarios do |scenario|
      migrate_solar_thermal(scenario)
      migrate_solar_hh(scenario)
      migrate_solar_b(scenario)
      migrate_industry_efficiency(scenario)
    end
  end

  private

  # SOLAR THERMAL
  # We have restructured the energy graph for households hot water and removed a child share
  # that limited the maximum amount of hot water supplied by solar thermal to households to 50%.
  # The existing input is maintained, so the same input now is applied to the full 100% of the
  # total useful demand for hot water. To mitigate this change, all inputs are set to 50% of their
  # original value.
  def migrate_solar_thermal(scenario)
    SOLAR_THERMAL.each do |key|
      next unless scenario.user_values.key?(key)

      scenario.user_values[key] = scenario.user_values[key] / 2.0
    end
  end


  # SOLAR
  # We have changed the solar panels on roofs (for buildings and households) from % of roof
  # surface potential to MW.
  # The % roof surface needs to be recalculated to MW. This is done by
  #   1. calculating the roof surface area,
  #   2. calculating the amount of units (solar panels) can be fit into that area using the
  #      land_use_per_unit and then
  #   3. multiplying this by the capacity of one unit (solar panel) using the
  #      electricity_output_capacity.
  def migrate_solar_hh(scenario)
    return unless Atlas::Dataset.exists?(scenario.area_code)

    SOLAR_HH.each do |old_key, new_key|
      if scenario.user_values.key?(old_key)
        scenario.user_values[new_key] = (
          (scenario.user_values.delete(old_key) / 100.0) *
          (scenario.area['residences_roof_surface_available_for_pv'] / LAND_USE_PER_UNIT_SOLAR) *
          ELEC_OUTPUT_CAP_SOLAR
        )
      end
    end
  end

  def migrate_solar_b(scenario)
    return unless Atlas::Dataset.exists?(scenario.area_code)

    SOLAR_B.each do |old_key, new_key|
      if scenario.user_values.key?(old_key)
        scenario.user_values[new_key] = (
          (scenario.user_values.delete(old_key) / 100.0) *
          (scenario.area['buildings_roof_surface_available_for_pv'] / LAND_USE_PER_UNIT_SOLAR) *
          ELEC_OUTPUT_CAP_SOLAR
        )
      end
    end
  end

  # INDUSTRY EFFICIENCIES
  # We have changed the efficiency sliders in industry from % per year to % total. This means
  # those sliders need to be recalculated in existing scenario's
  def migrate_industry_efficiency(scenario)
    # Inputs where we just recalulcate
    INDUSTRY_EFF.each do |eff_key|
      next unless scenario.user_values.key?(eff_key)

      scenario.user_values[eff_key] = recalculate_eff_input(scenario, eff_key)
    end

    # Inputs where we no longer allow negative efficiency. If a negative efficieny was set,
    # the input is reset to the start value of 0.0
    INDUSTRY_EFF_NO_NEGATIVE.each do |eff_key|
      next unless scenario.user_values.key?(eff_key)

      if scenario.user_values[eff_key].negative?
        scenario.user_values.delete(eff_key)
        next
      end

      scenario.user_values[eff_key] = recalculate_eff_input(scenario, eff_key)
    end

    # Inputs that have to supply a new value for multiple new sliders. The old input is deleted
    INDUSTRY_EFF_SPLIT_INPUTS.each do |old_key, new_keys|
      next unless scenario.user_values.key?(old_key)

      new_value = recalculate_eff_input(scenario, old_key)
      new_keys.each { |new_key| scenario.user_values[new_key] = new_value }
      scenario.user_values.delete(old_key)
    end
  end

  # Recalculates an input from per year to total % change
  def recalculate_eff_input(scenario, eff_key)
     (
      100.0 * (
        1.0 -
        1.0 / (
          (1.0 + scenario.user_values[eff_key] / 100.0) **
          (scenario.end_year - scenario.start_year)
        )
      )
    )
  end
end
