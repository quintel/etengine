class ChangeH2InputsNumberOfToCapacity < ActiveRecord::Migration[5.1]
  INPUTS = {
    energy_hydrogen_biomass_gasification: 468.080752390134,
    energy_hydrogen_flexibility_p2g_electricity: 10.0,
    energy_hydrogen_wind_turbine_offshore: 3.0,
    energy_hydrogen_solar_pv_solar_radiation: 20.0,
    energy_hydrogen_steam_methane_reformer: 504.470968364198,
    energy_hydrogen_steam_methane_reformer_ccs: 513.021323760201
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

  # All protected scenarios, and any unprotected scenarios since Jan 1st 2018
  # will be updated.
  def scenarios
    Scenario.where(
      '(protected = ? OR created_at >= ?) AND source != ? AND title != ?',
      true, Time.new(2018, 1, 1), 'Mechanical Turk', 'test'
    ).where(<<-SQL)
      (`user_values` IS NOT NULL OR `balanced_values` IS NOT NULL) AND
      (`user_values` != '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess {}\n' OR `balanced_values` != '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess {}\n')
    SQL
  end
end
