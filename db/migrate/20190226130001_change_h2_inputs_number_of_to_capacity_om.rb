class ChangeH2InputsNumberOfToCapacityOm < ActiveRecord::Migration[5.1]
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

  INPUTS = {
    energy_hydrogen_biomass_gasification: 468.080752390134,
    energy_hydrogen_flexibility_p2g_electricity: 10.0,
    energy_hydrogen_wind_turbine_offshore: 3.0,
    energy_hydrogen_solar_pv_solar_radiation: 20.0,
    energy_hydrogen_steam_methane_reformer: 504.470968364198,
    energy_hydrogen_steam_methane_reformer_ccs: 513.021323760201
  }.freeze

  def change
    return unless Rails.env.production?

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
    total = scenarios.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    scenarios.find_each.with_index do |scenario, index|
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

  def scenarios
    Scenario.where(id: SCENARIO_IDS)
  end
end
