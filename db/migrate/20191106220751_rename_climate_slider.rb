class RenameClimateSlider < ActiveRecord::Migration[5.2]
  OLD_KEY = 'households_climate_influence'.freeze
  NEW_KEY = 'flexibility_outdoor_temperature'.freeze

  def up
    update_scenarios do |scenario|
      next unless scenario.user_values.key?(OLD_KEY)

      scenario.user_values[NEW_KEY] = scenario.user_values.delete(OLD_KEY)
    end
  end

  def update_scenarios
    total = scenarios.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    scenarios.find_each.with_index do |scenario, index|
      if Atlas::Dataset.exists?(scenario.area_code)
        yield(scenario)

        if scenario.changed?
          scenario.save(validate: false, touch: false)
          changed += 1
        end
      end

      if index.positive? && (index % 1000).zero?
        say "#{index + 1}/#{total} (#{changed} migrated)"
      end
    end

    say "#{total}/#{total} (#{changed} migrated)"
  end

  # All protected scenarios, and any unprotected scenarios since Jan 1st 2019
  # will be updated.
  def scenarios
    Scenario.migratable_since(Date.new(2019, 1, 1))
  end
end
