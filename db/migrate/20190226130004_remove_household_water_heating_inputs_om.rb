# Remove water heating inputs from scenarios.
class RemoveHouseholdWaterHeatingInputsOm < ActiveRecord::Migration[5.1]
  SCENARIO_IDS = [
    361017, 361024, 361033, 361039, 361042, 362561, 362698, 362701, 362702,
    362705, 362708, 362710, 362712, 362719, 362724, 362774, 362775, 362776,
    362778, 362779, 362784, 362796, 362797, 362800, 362813, 362821, 362822,
    362826, 362827, 362828, 363625, 363626, 363639, 363641, 363643, 363644,
    363646, 363671, 363673, 363674, 363675, 363677, 363679, 364359, 364361,
    364363, 364365, 369748, 370161, 370165, 370167, 370316, 370376, 370539,
    371300, 371303, 371304, 371305, 371307, 371311, 371313, 371329, 371331,
    371333, 371667, 392431, 392442, 392446, 392448, 392458, 392459, 392462,
    392467, 392475, 392494, 392523, 392526, 392585, 392586, 392588, 392614,
    392628, 392637, 392651, 392653, 392664, 392668, 393020, 393034, 393039,
    393041, 393042, 393044, 393046, 393047, 393068, 393073, 393075, 393077,
    393079, 393081, 393097, 393119, 393131, 393133, 393140, 394273, 395436,
    395450, 384608
  ].freeze

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
    return unless Rails.env.production?

    say "#{scenarios.count} scenarios to be checked..."
    updated = 0
    skipped = 0

    scenarios.find_each.with_index do |scenario, index|
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
        scenario.save(validate: false, touch: false)
        updated += 1
      else
        skipped += 1
      end
    end
  end

  def down
    return unless Rails.env.production?
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

  def scenarios
    Scenario.where(id: SCENARIO_IDS)
  end
end
