require 'etengine/scenario_migration'

class BuiltEnvironmentHeatInputs < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  HOUSING_STOCK_RESIDENCES_OLD = 'households_number_of_residences'.freeze

  HOUSING_STOCK_SHARES_OLD = %w[
    households_apartments_share
    households_corner_houses_share
    households_detached_houses_share
    households_semi_detached_houses_share
    households_terraced_houses_share
  ].freeze

  HOUSING_STOCK_OLD = HOUSING_STOCK_SHARES_OLD + [HOUSING_STOCK_RESIDENCES_OLD]

  HOUSING_PERSON_DEMAND_OLD = 'households_useful_demand_heat_per_person'.freeze

  HOUSING_INSULATION_OLD = %w[
    households_insulation_level_apartments
    households_insulation_level_corner_houses
    households_insulation_level_detached_houses
    households_insulation_level_semi_detached_houses
    households_insulation_level_terraced_houses
  ].freeze

  HOUSING_INSULATION_ALL_OLD = HOUSING_INSULATION_OLD + [HOUSING_PERSON_DEMAND_OLD]

  HOUSING_STOCK_AGES_NEW = %w[before_1945 1945_1964 1965_1984 1985_2004 2005_present].freeze

  USER_CURVES_OLD = %w[
    weather/insulation_corner_houses_low_curve
    weather/insulation_corner_houses_medium_curve
    weather/insulation_corner_houses_high_curve
  ].freeze

  def up
    @defaults = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    migrate_scenarios do |scenario|
      next unless Atlas::Dataset.exists?(scenario.area_code)

      # When any housing stock inputs were touched, migrate the housing stock
      migrate_housing_stock(scenario) unless (scenario.user_values.keys & HOUSING_STOCK_OLD).empty?

      # When any housing insulation inputs were touched, migrate the housing insulation
      unless (scenario.user_values.keys & HOUSING_INSULATION_ALL_OLD).empty?
        migrate_insulation(scenario)
      end

      # When any building stock inputs were touched, migrate the building stock
      migrate_building_stock(scenario) if scenario.user_values.key?('number_of_buildings')

      # When any building insulation inputs were touched, migrate the building insulation
      if (scenario.user_values.key?('buildings_insulation_level') ||
        scenario.user_values.key?('buildings_useful_demand_for_space_heating'))
        migrate_buildings_insulation(scenario)
      end

      remove_old_user_curves(scenario)

      # REMOVE OLD SLIDERS
    end
  end

  def down

  end

  private

  def migrate_housing_stock(scenario)
    total_residences = value_or_default(scenario, HOUSING_STOCK_RESIDENCES_OLD)

    HOUSING_STOCK_SHARES_OLD.each do |housing_share|
      # Remove the first and last part of the share name to get the base housing type
      housing_type_base = housing_share[(housing_share.index('_')+1)...housing_share.rindex('_')]

      next if housing_type_base == 'corner_houses'
      if housing_type_base == 'semi_detached_houses' && !scenario.area['has_semi_detached_houses']
        next
      end

      total_future = total_residences * value_or_default(scenario, housing_share) / 100.0

      # Add the corner houses to the semi_detached if there are semi_detached houses
      if housing_type_base == 'semi_detached_houses'
        total_future += total_residences *
          value_or_default(scenario, 'households_corner_houses_share') / 100.0
      end
      # Add the corner houses and semi_detached to the detached if there are no semi_detached houses
      if housing_type_base == 'detached_houses' && !scenario.area['has_semi_detached_houses']
        total_future += total_residences *
          (value_or_default(scenario, 'households_corner_houses_share') +
          value_or_default(scenario, 'households_semi_detached_houses_share')) / 100.0
      end

      total_present = HOUSING_STOCK_AGES_NEW.sum(0.0) do |age|
        scenario.area["present_number_of_#{housing_type_base}_#{age}"]
      end

      # Nothing changed for this housing type. Move to the next one.
      next if total_future == total_present

      # There were more houses built. These are added as future age houses.
      # Move on to the next housing type.
      if total_future > total_present
        future_future = total_future - total_present
        scenario.user_values["households_number_of_#{housing_type_base}_future"] = future_future
        next
      end

      # Something changed. Calculate the new number of houses for each age based on the
      # area attribute for this housing type and age.
      change = total_future / total_present
      HOUSING_STOCK_AGES_NEW.each do |age|
        scenario.user_values["households_number_of_#{housing_type_base}_#{age}"] = (
          scenario.area["present_number_of_#{housing_type_base}_#{age}"] * change
        )
      end
    end

    remove_old_inputs(scenario, *HOUSING_STOCK_OLD)
  end

  def migrate_insulation(scenario)
    demand_change = change_in(scenario, value_or_default(scenario, HOUSING_PERSON_DEMAND_OLD))

    # Create a hash with all deltas for the different housing types
    deltas = HOUSING_INSULATION_OLD.inject({}) do |hash, insulation_input|
      housing_type = insulation_input.split('_')[3..].join('_')

      hash[housing_type] = (
        (value_or_default(scenario, insulation_input) -
        @defaults[scenario.area_code.to_s]["insulation_#{housing_type}_start_value"]) / 100.0
      )
      hash
    end

    # Special case for semi detached houses
    if scenario.area['has_semi_detached_houses']
      deltas['semi_detached_houses'] = (
        deltas['semi_detached_houses'] +
        deltas.delete('corner_houses')
      ) / 2.0
    else
      deltas['detached_houses'] = (
        deltas['detached_houses'] +
        deltas.delete('semi_detached_houses') +
        deltas.delete('corner_houses')
      ) / 3.0
    end

    # Set new insulation inputs based on calculated deltas
    deltas.each do |housing_type, delta|
      (HOUSING_STOCK_AGES_NEW + ['future']).each do |age|
        scenario.user_values["households_insulation_level_#{housing_type}_#{age}"] = (
          scenario.area["typical_useful_demand_for_space_heating_#{housing_type}_#{age}"] *
          (1.0 - delta) *
          demand_change
        )
      end
    end

    remove_old_inputs(scenario, *HOUSING_INSULATION_ALL_OLD)
  end

  def migrate_building_stock(scenario)
    building_stock_change = change_in(scenario, scenario.user_values['number_of_buildings'])

    if building_stock_change > 1
      scenario.user_values['buildings_number_of_buildings_future'] = (
        scenario.area['present_number_of_buildings'] *
        building_stock_change -
        scenario.area['present_number_of_buildings']
      )
    elsif building_stock_change < 1
      scenario.user_values['buildings_number_of_buildings_present'] = (
        scenario.area['present_number_of_buildings'] *
        building_stock_change
      )
    end

    scenario.user_values.delete('number_of_buildings')
  end

  def migrate_buildings_insulation(scenario)
    change = (
      1.0 -
      ( # delta insulation
        value_or_default(scenario, 'buildings_insulation_level') -
        @defaults[scenario.area_code.to_s]['insulation_buildings_start_value']
      ) / 100.0
    ) * # demand change
    change_in(scenario, value_or_default(scenario, 'buildings_useful_demand_for_space_heating'))

    scenario.user_values['buildings_insulation_level_buildings_present'] = (
      scenario.area['typical_useful_demand_for_space_heating_buildings_present'] * change
    )
    scenario.user_values['buildings_insulation_level_buildings_future'] = (
      scenario.area['typical_useful_demand_for_space_heating_buildings_future'] * change
    )

    remove_old_inputs(scenario,
      'buildings_insulation_level', 'buildings_useful_demand_for_space_heating'
    )
  end

  # Checks if the key was either present as user value, balanced value or
  # needs to be looked up in the defaults
  def value_or_default(scenario, key)
    return scenario.user_values[key] if scenario.user_values.key? key
    return scenario.balanced_values[key] if scenario.balanced_values.key? key

    # Do a lookup in the defaults
    value = @defaults[scenario.area_code.to_s][key]
    key.end_with?('share') ? value * 100.0 : value
  end

  # The change in the scenario for the value between the start and end year
  def change_in(scenario, value)
    (1.0 + value / 100.0) ** (scenario.end_year - scenario.start_year)
  end

  def remove_old_inputs(scenario, *inputs)
    inputs.each do |input|
      scenario.user_values.delete(input) if scenario.user_values.key?(input)
    end
  end

  def remove_old_user_curves(scenario)
    USER_CURVES_OLD.each do |curve_key|
      next unless scenario.attachment?(curve_key)

      scenario.attachment(curve_key).destroy!
    end
  end
end
