require 'etengine/scenario_migration'

class ChemicalsAndSyntheticProducts < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  FOSSIL_KEY = 'industry_useful_demand_for_chemical_refineries'
  FOSSIL_KEYS = %w[ energy_export_oil_products
                    energy_distribution_diesel
                    energy_distribution_gasoline
                    energy_distribution_heavy_fuel_oil
                    energy_distribution_kerosene
                    energy_distribution_lpg
                    energy_distribution_naphtha
                    industry_locally_available_refinery_gas_for_chemical].freeze

  KEROSENE_OLD_KEY = 'output_of_energy_production_synthetic_kerosene_must_run'
  KEROSENE_NEW_KEY = 'output_of_energy_production_fischer_tropsch'
  KEROSENE_OUTPUT_CONVERSION_CORRECTION = 1.5

  WP_KEY = 'external_coupling_industry_chemical_other_non_energetic_wood_pellets_share'
  BION_KEY = 'external_coupling_industry_chemical_other_non_energetic_bionaphtha_share'

  RENAME = {
    'capacity_of_energy_production_synthetic_kerosene_dispatchable' => ['capacity_of_energy_production_fischer_tropsch_synthetic_dispatchable'],
    'investment_costs_co2_utilisation' => ['investment_costs_fischer_tropsch', 'investment_costs_methanol_synthesis'],
    'om_costs_co2_utilisation' => ['om_costs_methanol_synthesis', 'om_costs_fischer_tropsch'],
    'transport_plane_using_kerosene_share' => ['transport_plane_using_kerosene_mix_share'],
    'external_coupling_energy_chemical_other_transformation_external_coupling_node_bio_oil_output_share' => ['external_coupling_energy_chemical_other_transformation_external_coupling_node_bionaphtha_output_share'],
    'external_coupling_energy_chemical_refineries_transformation_external_coupling_node_bio_oil_output_share' => ['external_coupling_energy_chemical_refineries_transformation_external_coupling_node_bionaphtha_output_share'],
    'external_coupling_energy_chemical_fertilizers_transformation_external_coupling_node_bio_oil_output_share' => ['external_coupling_energy_chemical_fertilizers_transformation_external_coupling_node_bionaphtha_output_share'],
    'output_of_energy_production_synthetic_methanol' => ['output_of_energy_production_methanol_synthesis']
  }.freeze

  REMOVE = %w[external_coupling_energy_production_synthetic_methanol_demand
              external_coupling_energy_production_synthetic_kerosene_demand
              capacity_of_energy_production_synthetic_kerosene_dispatchable
              investment_costs_co2_utilisation
              om_costs_co2_utilisation
              transport_plane_using_kerosene_share
              external_coupling_energy_chemical_other_transformation_external_coupling_node_bio_oil_output_share
              external_coupling_energy_chemical_refineries_transformation_external_coupling_node_bio_oil_output_share
              external_coupling_energy_chemical_fertilizers_transformation_external_coupling_node_bio_oil_output_share
              output_of_energy_production_synthetic_methanol]

  def up
    @defaults = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    migrate_scenarios do |scenario|
      migrate_fossil_refinery(scenario)
      migrate_synthetic_kerosene(scenario)
      migrate_ext_coupling_bionaphtha(scenario)
      rename_inputs(scenario)
      remove_inputs(scenario)
    end
  end

  private

  def migrate_fossil_refinery(scenario)
    return unless scenario.user_values.key?(FOSSIL_KEY)
    dataset_refinery_size = 0
    FOSSIL_KEYS.each do |key|
      dataset_refinery_size += @defaults[scenario.area_code][key] / 1000
    end
    scenario.user_values[FOSSIL_KEY] = (scenario.user_values[FOSSIL_KEY] / 100) * dataset_refinery_size
  end

  def migrate_synthetic_kerosene(scenario)
    return unless scenario.user_values.key?(KEROSENE_OLD_KEY)
    scenario.user_values[KEROSENE_NEW_KEY] = scenario.user_values.delete(KEROSENE_OLD_KEY) * KEROSENE_OUTPUT_CONVERSION_CORRECTION
  end

  def migrate_ext_coupling_bionaphtha(scenario)
    return unless scenario.user_values.key?(WP_KEY)
    wood_pellets = scenario.user_values[WP_KEY]
    scenario.user_values[BION_KEY] = wood_pellets
    scenario.user_values[WP_KEY] = 0.0
  end

  def rename_inputs(scenario)
    RENAME.each do |old_key, new_keys|
      next unless scenario.user_values.key?(old_key)
      Array(new_keys).each do |new_key|
        scenario.user_values[new_key] = scenario.user_values[old_key]
      end
    end
  end

  def remove_inputs(scenario)
    REMOVE.each do |key|
      next unless scenario.user_values.key?(key)
      scenario.user_values.delete(key)
    end
  end
end
