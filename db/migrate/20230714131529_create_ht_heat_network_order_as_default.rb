require 'etengine/scenario_migration'

class CreateHtHeatNetworkOrderAsDefault < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  RENAME_INPUTS = {
    "capacity_of_energy_heat_well_geothermal" => "capacity_of_energy_heat_well_deep_ht_geothermal",
    "capacity_of_energy_heat_solar_thermal" => "capacity_of_energy_heat_solar_ht_solar_thermal",
    "capacity_of_energy_heat_heatpump_water_water_electricity" => "capacity_of_energy_heat_heatpump_water_water_ht_electricity",
    "capacity_of_energy_heat_boiler_electricity" => "capacity_of_energy_heat_boiler_ht_electricity",
    "capacity_of_energy_heat_burner_network_gas" => "capacity_of_energy_heat_burner_ht_network_gas",
    "capacity_of_energy_heat_burner_hydrogen" => "capacity_of_energy_heat_burner_ht_hydrogen",
    "capacity_of_energy_heat_burner_wood_pellets" => "capacity_of_energy_heat_burner_ht_wood_pellets",
    "capacity_of_energy_heat_burner_waste_mix" => "capacity_of_energy_heat_burner_ht_waste_mix",
    "capacity_of_energy_heat_burner_crude_oil" => "capacity_of_energy_heat_burner_ht_crude_oil",
    "capacity_of_energy_heat_burner_coal" => "capacity_of_energy_heat_burner_ht_coal",
    "energy_heat_distribution_loss_share" => "energy_heat_distribution_ht_loss_share",
    "volume_of_imported_heat" => "volume_of_ht_imported_heat",
    "co2_emissions_of_imported_heat" => "co2_emissions_of_imported_heat",
    "heat_storage_enabled" => "heat_storage_enabled_ht",
    "energy_heat_network_storage_loss_share" => "energy_heat_network_storage_ht_loss_share",
    "energy_heat_network_storage_output_capacity_share" => "energy_heat_network_storage_ht_steam_hot_water_output_capacity_share",
    "share_of_industry_chemicals_other_reused_residual_heat" => "share_of_industry_chemicals_other_reused_residual_heat",
    "share_of_industry_chemicals_fertilizers_reused_residual_heat" => "share_of_industry_chemicals_fertilizers_reused_residual_heat",
    "share_of_industry_chemicals_refineries_reused_residual_heat" => "share_of_industry_chemicals_refineries_reused_residual_heat",
    "share_of_industry_other_ict_reused_residual_heat" => "share_of_industry_other_ict_reused_residual_heat",
    "share_of_energy_chp_supercritical_ccs_waste_mix" => "share_of_energy_chp_supercritical_ccs_ht_waste_mix"
  }

  ORDER_TRANSLATIONS = {
    "energy_heat_network_storage" => "energy_heat_network_storage_ht_steam_hot_water",
    "energy_heat_burner_waste_mix" => "energy_heat_boiler_ht_electricity",
    "energy_heat_heatpump_water_water_electricity" => "energy_heat_burner_ht_coal",
    "energy_heat_burner_coal" => "energy_heat_burner_ht_crude_oil",
    "energy_heat_burner_network_gas" => "energy_heat_burner_ht_hydrogen",
    "energy_heat_burner_wood_pellets" => "energy_heat_burner_ht_network_gas",
    "energy_heat_burner_crude_oil" => "energy_heat_burner_ht_waste_mix",
    "energy_heat_burner_hydrogen" => "energy_heat_burner_ht_wood_pellets",
    "energy_heat_boiler_electricity" => "energy_heat_heatpump_water_water_ht_electricity"
  }

  def up

    migrate_scenarios do |scenario|
      # Rename old heat network inputs to be standard HT, even when custom order was not touched
      RENAME_INPUTS.each do |from, to|
        rename_input(scenario, from, to)
      end

      next if scenario.heat_network_orders.blank?

      # In the last migration we set the default temperature level to MT
      # So each scenario that already had a custom order set, now has it only for MT
      # In this migration we set a new order for HT based on the mapping to new keys, and remove the one for MT
      old_mt_order = scenario.heat_network_order(:mt)

      scenario.heat_network_orders << HeatNetworkOrder.new(order: translate(old_mt_order.order), temperature: :ht)
      old_mt_order.destroy!

      scenario.save(validate: false, touch: false)
    end
  end

  private

  def rename_input(scenario, from, to)
    if scenario.user_values.key?(from)
      scenario.user_values[to] = scenario.user_values.delete(from)
    end
  end

  def translate(old_order)
    old_order.map { |old_key| ORDER_TRANSLATIONS[old_key] }
  end
end
