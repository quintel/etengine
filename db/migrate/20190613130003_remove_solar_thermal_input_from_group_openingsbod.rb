# Removes the solar thermal input from scenarios. This was previously part of
# the household heating share group, so affected scenarios must rebalance the
# group.
class RemoveSolarThermalInputFromGroupOpeningsbod < ActiveRecord::Migration[5.1]
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
    ids = Pathname.new(__FILE__)
      .expand_path
      .dirname
      .join('20190613130000_protect_openingsbod_cp_scenarios/scenario_ids.csv')
      .read
      .lines
      .map(&:to_i)

    Scenario.where(id: ids)
  end
end
