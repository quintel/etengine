class ChangeOtherSupplyInputsToCapacity < ActiveRecord::Migration[5.1]
  INPUTS = {
    agriculture_chp_engine_biogas: 1.11111111,
    agriculture_chp_engine_network_gas: 2.18604651162791,
    agriculture_chp_supercritical_wood_pellets: 6.375,
    energy_chp_combined_cycle_network_gas: 120,
    energy_chp_supercritical_waste_mix: 60,
    energy_chp_ultra_supercritical_coal: 695.652173913043,
    energy_chp_ultra_supercritical_cofiring_coal: 643.478260869565,
    energy_chp_ultra_supercritical_lignite: 700,
    energy_flexibility_pumped_storage_electricity: 500,
    energy_heater_for_heat_network_wood_pellets: 100,
    energy_heater_for_heat_network_coal: 100,
    energy_heater_for_heat_network_oil: 100,
    energy_heater_for_heat_network_geothermal: 8.5,
    energy_heater_for_heat_network_lignite: 5,
    energy_heater_for_heat_network_network_gas: 100,
    energy_heater_for_heat_network_waste_mix: 5,
    energy_power_combined_cycle_ccs_coal: 658,
    energy_power_combined_cycle_coal: 800,
    energy_power_combined_cycle_hydrogen: 800,
    energy_power_combined_cycle_network_gas: 800,
    energy_power_combined_cycle_ccs_network_gas: 665,
    energy_power_engine_diesel: 2,
    energy_power_engine_network_gas: 400,
    energy_power_geothermal: 12,
    energy_power_hydro_mountain: 500,
    energy_power_hydro_river: 10,
    energy_power_nuclear_gen2_uranium_oxide: 1650,
    energy_power_nuclear_gen3_uranium_oxide: 1650,
    energy_power_solar_csp_solar_radiation: 50,
    energy_power_supercritical_coal: 800,
    energy_power_supercritical_waste_mix: 55.56,
    energy_power_turbine_hydrogen: 150,
    energy_power_turbine_network_gas: 150,
    energy_power_ultra_supercritical_coal: 800,
    energy_power_ultra_supercritical_ccs_coal: 637,
    energy_power_ultra_supercritical_cofiring_coal: 730.434782608696,
    energy_power_ultra_supercritical_crude_oil: 800,
    energy_power_ultra_supercritical_lignite: 800,
    energy_power_ultra_supercritical_network_gas: 800,
    energy_power_ultra_supercritical_oxyfuel_ccs_lignite: 660,
    energy_power_wind_turbine_coastal: 3,
    energy_power_wind_turbine_inland: 3,
    energy_power_wind_turbine_offshore: 3,
    flexibility_p2l_electricity: 10.6543592563728,
    industry_chemicals_other_flexibility_p2h_electricity: 50,
    industry_chemicals_refineries_flexibility_p2h_electricity: 50,
    industry_chp_combined_cycle_gas_power_fuelmix: 95.2380952380952,
    industry_chp_engine_gas_power_fuelmix: 1.14286,
    industry_chp_turbine_gas_power_fuelmix: 49.73684,
    industry_chp_ultra_supercritical_coal: 20.2546296296296,
    industry_other_food_flexibility_p2h_electricity: 50,
    industry_other_paper_flexibility_p2h_electricity: 50
  }.freeze

  def change
    reversible do |dir|
      dir.up do
        update_scenarios(INPUTS, 'number_of', 'capacity_of')
      end

      dir.down do
        update_scenarios(
          INPUTS.transform_values { |v| 1 / v },
          'capacity_of',
          'number_of'
        )
      end
    end
  end

  private

  def update_scenarios(collection, from_prefix, to_prefix)
    total = Scenario.migratable.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    Scenario.migratable.find_each.with_index do |scenario, index|
      updated = collection.reduce(false) do |memo, (key, multiplier)|
        update_input(
          scenario,
          "#{from_prefix}_#{key}",
          "#{to_prefix}_#{key}",
          multiplier
        ) || memo
      end

      if updated
        scenario.save(validate: false)
        changed += 1
      end

      say "#{index + 1}/#{total} (#{changed} migrated)" if (index % 1000).zero?
    end

    say "#{total}/#{total} (#{changed} migrated)"
  end

  # Changes an input in a `scenario` from the `from` key to the `to` key,
  # multiplying the value by `multiplier`.
  #
  # If the `from` key is not present, returns a falsey value.
  def update_input(scenario, from, to, multiplier)
    if scenario.user_values.key?(from)
      scenario.user_values[to] = scenario.user_values.delete(from) * multiplier
      true
    end
  end

end
