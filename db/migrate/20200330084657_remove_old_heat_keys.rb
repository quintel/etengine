require 'etengine/scenario_migration'

class RemoveOldHeatKeys < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  OLD_HEAT_KEYS = %w[
    buildings_chp_engine_biogas_share
    buildings_collective_burner_hydrogen_share
    buildings_collective_burner_network_gas_share
    buildings_collective_chp_wood_pellets_share
    buildings_collective_geothermal_share
    buildings_collective_heatpump_water_water_electricity_share
    capacity_of_agriculture_chp_engine_biogas
    capacity_of_agriculture_chp_engine_network_gas
    capacity_of_agriculture_chp_supercritical_wood_pellets
    capacity_of_energy_chp_engine_biogas
    capacity_of_energy_heater_for_heat_network_coal
    capacity_of_energy_heater_for_heat_network_geothermal
    capacity_of_energy_heater_for_heat_network_lignite
    capacity_of_energy_heater_for_heat_network_network_gas
    capacity_of_energy_heater_for_heat_network_oil
    capacity_of_energy_heater_for_heat_network_waste_mix
    capacity_of_energy_heater_for_heat_network_wood_pellets
    households_collective_burner_hydrogen_share
    households_collective_burner_network_gas_share
    households_collective_chp_biogas_share
    households_collective_chp_network_gas_share
    households_collective_chp_wood_pellets_share
    households_collective_geothermal_share
    households_collective_heatpump_water_water_electricity_share
    households_flexibility_p2h_electricity_market_penetration
    investment_costs_earth_geothermal_electricity
    investment_costs_heat_network_buildings
    investment_costs_heat_network_households
    om_costs_earth_geothermal_electricity
    om_costs_heat_network_buildings
    om_costs_heat_network_households
  ].freeze


  def up
    migrate_scenarios(since: Date.new(2020, 2, 1)) do |scenario|
      OLD_HEAT_KEYS.each do |key|
        scenario.user_values.delete(key)
      end
    end
  end
end
