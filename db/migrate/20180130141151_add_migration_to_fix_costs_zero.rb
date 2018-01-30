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

    # Step 2: Get all the start values for price_of_gas, price_of_oil, etc.
    #
    # This is per area
    puts "#{ Time.now } | Calculating defaults"

    defaults = scenarios.pluck(:area_code).uniq
      .each_with_object({}) do |area_code, obj|
        scenario = Scenario.new(area_code: area_code)

        begin
          gql = scenario.gql

          obj[area_code] = KEYS.each_with_object({}) do |(key, gql_key), start|
            start[key] = gql.present.query(gql_key)
          end
        rescue StandardError => e
          puts "#{ e }"
        end
    end

    # Step 3: Setting some timers for logging
    puts "#{ Time.now } | Need to migrate #{ scenarios.count } scenarios"

    migrated = 0

    scenarios.find_each do |scenario|
      costs = scenario.user_values.slice(*KEYS.keys)

      next if !scenario.valid? || costs.empty?

      costs.each_pair do |key, val|
        if val.zero?
          puts "#{ Time.now } | Migrating #{ scenario.id } | #{ key }"
          scenario.user_values[key] = (defaults[scenario.area_code][key.to_sym] * (1 + (val / 100.0)))
        end
      end

      scenario.save

      migrated += 1
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
