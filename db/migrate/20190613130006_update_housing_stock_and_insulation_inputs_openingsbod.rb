# frozen_string_literal: true
class UpdateHousingStockAndInsulationInputsOpeningsbod < ActiveRecord::Migration[5.1]
  HOUSING_TYPES = %i[
    apartments
    corner_houses
    detached_houses
    semi_detached_houses
    terraced_houses
  ].freeze

  INSULATION_RANGE = {
    apartments: 54.0,
    corner_houses: 60.0,
    detached_houses: 56.0,
    semi_detached_houses: 56.0,
    terraced_houses: 56.0
  }.freeze

  INSULATION_MAX = {
    apartments: 0.67,
    buildings: 0.74,
    corner_houses: 0.69,
    detached_houses: 0.67,
    semi_detached_houses: 0.69,
    terraced_houses: 0.69
  }.freeze

  def up
    return unless Rails.env.production?

    say "#{scenarios.count} scenarios to be checked..."
    updated = 0

    dir = Pathname.new(__FILE__).expand_path.dirname.join('20190124131252_update_housing_stock_and_insulation_inputs')

    new_defaults = values_to_floats(JSON.parse(File.read(dir.join('defaults_new.json'))))
    old_defaults = values_to_floats(JSON.parse(File.read(dir.join('defaults_old.json'))))
    analysis_years = JSON.parse(File.read(dir.join('analysis_years.json')))

    scenarios.find_each.with_index do |scenario, index|
      say "#{index} done" if index.positive? && (index % 250).zero?

      scenario_new_defaults = new_defaults[scenario.area_code]
      scenario_old_defaults = old_defaults[scenario.area_code]

      next unless scenario_new_defaults && scenario_old_defaults

      changed_stock = update_stock(
        scenario,
        scenario_new_defaults,
        scenario_old_defaults
      )

      changed_housing = update_housing_insulation(
        scenario,
        scenario_new_defaults,
        scenario_old_defaults,
        analysis_years[scenario.area_code]
      )

      changed_buildings = update_buildings_insulation(
        scenario,
        scenario_new_defaults
      )

      if changed_stock || changed_housing || changed_buildings
        scenario.user_values.delete('households_number_of_old_houses')
        scenario.user_values.delete('households_number_of_new_houses')

        scenario.user_values.delete('households_insulation_level_old_houses')
        scenario.user_values.delete('households_insulation_level_new_houses')

        scenario.save(validate: false, touch: false)

        updated += 1
      end
    end

    say "Finished. Updated #{updated} scenarios."
  end

  def down
    return unless Rails.env.production?
    raise ActiveRecord::IrreversibleMigration
  end

  # Housing Stock

  # Updates housing stock (amount of each type of household) based on the number
  # of old and new households.
  def update_stock(scenario, new_defaults, old_defaults)
    if !scenario.user_values.key?('households_number_of_old_houses') &&
        !scenario.user_values.key?('households_number_of_new_houses')
      return false
    end

    HOUSING_TYPES.each do |key|
      scenario.user_values["households_number_of_#{key}"] =
        update_stock_key(
          "number_of_#{key}",
          scenario,
          new_defaults,
          old_defaults
        )
    end

    true
  end

  # Updates housing stock for one type of housing.
  def update_stock_key(key, scenario, new_defaults, old_defaults)
    old_number_of_residences =
      old_defaults['number_of_old_residences'] +
      old_defaults['number_of_new_residences']

    share = new_defaults[key] / old_number_of_residences
    share * number_of_residences(scenario, old_defaults)
  end

  # Insulation

  def update_housing_insulation(scenario, new_defaults, old_defaults, analysis_year)
    if !scenario.user_values['households_insulation_level_old_houses'] &&
        !scenario.user_values['households_insulation_level_new_houses'] ||
        old_defaults['number_of_old_residences'].zero? ||
        old_defaults['number_of_new_residences'].zero?
      return false
    end

    saving_fraction_old = 1.0 - 0.66 / #
      ((scenario.user_values['households_insulation_level_old_houses'] || 0.5) + 0.16)

    saving_fraction_new = 1.0 - 1.85 / #
      ((scenario.user_values['households_insulation_level_new_houses'] || 1.8) + 0.05)

    heat_demand_change =
      (1.0 + (scenario.user_values['households_useful_demand_heat_per_person'] || 0.0) / 100.0) **
      (scenario.end_year - analysis_year)

    future_ud_old =
      old_defaults['households_old_houses_useful_demand_for_heating'] *
      (nor_value(scenario, old_defaults, :old) / old_defaults['number_of_old_residences']) *
      heat_demand_change

    future_ud_new =
      old_defaults['households_new_houses_useful_demand_for_heating'] *
      (nor_value(scenario, old_defaults, :new) / old_defaults['number_of_new_residences']) *
      heat_demand_change

    # Do nothing when there is no demand (no residences).
    return if future_ud_old.zero? && future_ud_new.zero?

    average_saving =
      (saving_fraction_old * future_ud_old + saving_fraction_new * future_ud_new) / #
      (future_ud_old + future_ud_new)

    HOUSING_TYPES.each do |type|
      scenario.user_values["households_insulation_level_#{type}"] =
        100.0 * [
          1.0 -
            (1.0 - (new_defaults["insulation_#{type}_start_value"] / 100.0)) *
            (1.0 - average_saving),
          INSULATION_MAX[type]
        ].min
    end

    true
  end

  def update_buildings_insulation(scenario, defaults)
    return false unless scenario.user_values['buildings_insulation_level']

    old_value = scenario.user_values['buildings_insulation_level']
    start_value = defaults['insulation_buildings_start_value']

    saving_fraction = 1.0 - 0.73 / (old_value + 0.13)

    scenario.user_values['buildings_insulation_level'] =
      100.0 * [
        1.0 -
          (1.0 - start_value / 100.0) *
          (1.0 - saving_fraction),
        INSULATION_MAX[:buildings]
      ].min
  end

  # Helpers

  # Calculates the total number of residences by summing the old and new falling
  # back to the defaults if necessary.
  def number_of_residences(scenario, defaults)
    nor_value(scenario, defaults, :old) + nor_value(scenario, defaults, :new)
  end

  # Number of residences value: old or new households. Accounts for the input
  # value being in multiples of a million while the defaults are not.
  def nor_value(scenario, defaults, period)
    if scenario.user_values.key?("households_number_of_#{period}_houses")
      scenario.user_values["households_number_of_#{period}_houses"] * 1_000_000
    else
      defaults["number_of_#{period}_residences"]
    end
  end

  def values_to_floats(defaults)
    Hash[defaults.map { |k, v| [k, v.transform_values(&:to_f)] }]
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
