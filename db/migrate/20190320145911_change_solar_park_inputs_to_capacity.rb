class ChangeSolarParkInputsToCapacity < ActiveRecord::Migration[5.1]
  INPUT_KEY = 'energy_power_solar_pv_solar_radiation'.freeze
  INPUT_MULTIPLIER = 20.0

  def change
    reversible do |dir|
      dir.up do
        update_scenarios(INPUT_MULTIPLIER, 'number_of', 'capacity_of')
      end

      dir.down do
        update_scenarios(1 / INPUT_MULTIPLIER, 'capacity_of', 'number_of')
      end
    end
  end

  private

  def update_scenarios(multiplier, from_prefix, to_prefix)
    total = Scenario.migratable.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    Scenario.migratable.find_each.with_index do |scenario, index|
      from = "#{from_prefix}_#{INPUT_KEY}"
      to = "#{to_prefix}_#{INPUT_KEY}"

      if scenario.user_values.key?(from)
        scenario.user_values[to] =
          scenario.user_values.delete(from) * multiplier

        scenario.save(validate: false)
        changed += 1
      end

      say "#{index + 1}/#{total} (#{changed} migrated)" if (index % 1000).zero?
    end

    say "#{total}/#{total} (#{changed} migrated)"
  end
end
