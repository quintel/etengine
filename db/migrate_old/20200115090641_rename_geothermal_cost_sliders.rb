class RenameGeothermalCostSliders < ActiveRecord::Migration[5.2]
  KEYS = {
    'investment_costs_earth_geothermal_electricity' => 'investment_costs_geothermal',
    'om_costs_earth_geothermal_electricity' => 'om_costs_geothermal'
  }.freeze

  def up
    update_scenarios do |scenario|
      KEYS.each do |old_key, new_key|
        if scenario.user_values.key?(old_key)
          scenario.user_values[new_key] = scenario.user_values.delete(old_key)
        end
      end
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
    Scenario.migratable_since(Date.new(2019, 10, 1))
  end
end
