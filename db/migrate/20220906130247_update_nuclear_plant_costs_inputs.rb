# frozen_string_literal: true

# See https://github.com/quintel/etengine/issues/1268
class UpdateNuclearPlantCostsInputs < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  UPDATES = {
    investment_costs_nuclear_nuclear_plant: [4_950_000_000.0, 6_992_000_000.0],
    om_costs_nuclear_nuclear_plant: [6_288.0, 4_000.0]
  }

  def up
    UPDATES.each do |key, (before, after)|
      say_new_default(key, before, after)
    end

    migrate_scenarios do |scenario|
      UPDATES.each do |key, (before, after)|
        run(scenario, key, before, after)
      end
    end
  end

  def down
    UPDATES.each do |key, (after, before)|
      say_new_default(key, before, after)
    end

    migrate_scenarios do |scenario|
      UPDATES.each do |key, (after, before)|
        run(scenario, key, before, after, true)
      end
    end
  end

  private

  def say_new_default(key, before, after)
    say "New default for #{key}: #{default_value(before, after)}"
  end

  def default_value(before, after)
    ((before / after) - 1.0) * 100
  end

  def run(scenario, key, before, after, rollback = true)
    original_value = scenario.user_values[key]

    new_percentage =
      if original_value
        # Update existing value.
        factor = 1 + (original_value.to_f / 100)
        real_value = before * factor
        new_factor = real_value / after

        (new_factor - 1) * 100
      else
        # Set new default to match the old costs.
        default_value(before, after)
      end

    # When rolling back, if the value is 0% it's likely the original scenario had no value.
    # Remove it.
    if rollback && new_percentage.between?(-0.0001, 0.0001)
      scenario.user_values.delete(key)
    else
      scenario.user_values[key] = new_percentage.clamp(-100.0, 300.0)
    end
  end
end
