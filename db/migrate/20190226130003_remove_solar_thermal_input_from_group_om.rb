# Removes the solar thermal input from scenarios. This was previously part of
# the household heating share group, so affected scenarios must rebalance the
# group.
class RemoveSolarThermalInputFromGroupOm < ActiveRecord::Migration[5.1]
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
    395450
  ].freeze

  SOLAR_THERMAL_MAX = 13.0
  SOLAR_THERMAL_KEY = :buildings_space_heater_solar_thermal_share

  GROUP_KEYS = %i[
    buildings_space_heater_coal_share
    buildings_space_heater_collective_heatpump_water_water_ts_electricity_share
    buildings_space_heater_crude_oil_share
    buildings_space_heater_district_heating_steam_hot_water_share
    buildings_space_heater_electricity_share
    buildings_space_heater_heatpump_air_water_network_gas_share
    buildings_space_heater_network_gas_share
  ].freeze

  def up
    return unless Rails.env.production?

    say "#{scenarios.count} scenarios to be checked..."
    updated = 0
    skipped = 0

    scenarios.find_each.with_index do |scenario, index|
      say "#{updated + skipped} done" if index.positive? && (index % 250).zero?

      unless (st_val = solar_thermal(scenario))
        skipped += 1
        next
      end

      update_solar_thermal(scenario.user_values)
      update_solar_thermal(scenario.balanced_values)

      update_collection(scenario.user_values, st_val)
      update_collection(scenario.balanced_values, st_val)

      scenario.save(validate: false, touch: false)
      updated += 1
    end

    say "#{updated + skipped} done"
    say "Updated: #{updated}, not applicable: #{skipped}"
  end

  def down
    return unless Rails.env.production?
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def solar_thermal(scenario)
    scenario.user_values[SOLAR_THERMAL_KEY] ||
      scenario.balanced_values[SOLAR_THERMAL_KEY]
  end

  def update_solar_thermal(collection)
    val = collection[SOLAR_THERMAL_KEY]

    return unless val

    collection[SOLAR_THERMAL_KEY] = ((val / SOLAR_THERMAL_MAX) * 100).round(6)
    collection[SOLAR_THERMAL_KEY] = 100.0 if collection[SOLAR_THERMAL_KEY] > 100
  end

  def update_collection(collection, st_val)
    rebalance = 100.0 / (100 - st_val)

    GROUP_KEYS.each do |key|
      next unless collection[key]
      collection[key] = (collection[key] * rebalance).round(6)
    end
  end

  def scenarios
    Scenario.where(id: SCENARIO_IDS)
  end
end
