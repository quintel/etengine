# Remove water heating inputs from scenarios.
class RemoveHouseholdWaterHeatingInputs < ActiveRecord::Migration[5.1]
  HOT_WATER_INPUTS = %i[
    households_water_heater_coal_share
    households_water_heater_combined_network_gas_share
    households_water_heater_crude_oil_share
    households_water_heater_district_heating_steam_hot_water_share
    households_water_heater_fuel_cell_chp_network_gas_share
    households_water_heater_heatpump_air_water_electricity_share
    households_water_heater_heatpump_ground_water_electricity_share
    households_water_heater_hybrid_heatpump_air_water_electricity_share
    households_water_heater_micro_chp_network_gas_share
    households_water_heater_network_gas_share
    households_water_heater_resistive_electricity_share
    households_water_heater_wood_pellets_share
  ].freeze

  SPACE_HEATING_INPUTS = %i[
    households_space_heater_coal_share
    households_space_heater_combined_network_gas_share
    households_space_heater_crude_oil_share
    households_space_heater_district_heating_steam_hot_water_share
    households_space_heater_electricity_share
    households_space_heater_heatpump_air_water_electricity_share
    households_space_heater_heatpump_ground_water_electricity_share
    households_space_heater_hybrid_heatpump_air_water_electricity_share
    households_space_heater_micro_chp_network_gas_share
    households_space_heater_network_gas_share
    households_space_heater_wood_pellets_share
  ].freeze

  def up
    say "#{Scenario.migratable.count} scenarios to be checked..."
    updated = 0
    skipped = 0

    Scenario.migratable.find_each.with_index do |scenario, index|
      say "#{updated + skipped} done" if index.positive? && (index % 250).zero?
      has_changed = false

      if inputs?(HOT_WATER_INPUTS, scenario)
        HOT_WATER_INPUTS.each do |key|
          scenario.user_values.delete(key)
          scenario.balanced_values.delete(key)
        end

        has_changed = true
      end

      if inputs?(SPACE_HEATING_INPUTS, scenario)
        SPACE_HEATING_INPUTS.each do |key|
          rename_space_heating_input(key, scenario)
          has_changed = true
        end
      end

      if has_changed
        scenario.save(validate: false)
        updated += 1
      else
        skipped += 1
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def inputs?(inputs, scenario)
    inputs.any? do |key|
      scenario.user_values[key] || scenario.balanced_values[key]
    end
  end

  def rename_space_heating_input(name, scenario)
    new_name = name.to_s.sub('space_heater', 'heater')

    if scenario.user_values[name]
      scenario.user_values[new_name] = scenario.user_values.delete(name)
    elsif scenario.balanced_values[name]
      scenario.balanced_values[new_name] = scenario.balanced_values.delete(name)
    end
  end
end
