class AddMigrationToFixCostsZero < ActiveRecord::Migration[5.1]
  KEYS = {
    costs_gas:     :price_of_gas,
    costs_oil:     :price_of_oil,
    costs_coal:    :price_of_coal,
    costs_biomass: :price_of_wood_pellets,
    costs_co2:     :price_of_co2,
    costs_uranium: :price_of_uranium
  }

  def up
    # Step 1: Select scenarios
    scenarios = Scenario.where(
      '(protected = ? OR created_at >= ?) AND source != ? AND title != ?',
      true, 1.month.ago, 'Mechanical Turk', 'test'
    )

    defaults = JSON.parse(File.read(Rails.root.join("db", "migrate", "20180130141151_add_migration_to_fix_costs_zero", "defaults.json")))

    # Step 3: Setting some timers for logging
    puts "#{ Time.now } | Need to migrate #{ scenarios.count } scenarios"

    migrated = 0

    scenarios.find_each(batch_size: 5) do |scenario|
      raise 'HELL'
      costs = scenario.user_values.slice(*KEYS.keys)

      next if !scenario.valid? || costs.empty?

      if migrated % 100
        puts "#{ Time.now } | at #{ migrated } - #{ scenario.id }"
      end

      costs.each_pair do |key, val|
        scenario.user_values[key] = (defaults[scenario.area_code][key] * (1 + (val / 100.0)))
      end

      scenario.save

      migrated += 1
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
