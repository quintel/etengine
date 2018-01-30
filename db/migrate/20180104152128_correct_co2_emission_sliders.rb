class CorrectCo2EmissionSliders < ActiveRecord::Migration[5.1]
  KG_PER_MJ_IN_G_PER_KWH = 3600.0

  def up
    count     = 0
    gquery    = Gquery.get(:average_co2_emissions_of_produced_electricity)
    scenarios = Scenario.where(
      '(protected = ? OR created_at >= ?) AND source != ? AND title != ?',
      true, 1.month.ago, 'Mechanical Turk', 'test'
    ).order(:area_code)

    puts "Need to migrate: #{ scenarios.count } scenarios"

    scenarios.find_each(batch_size: 5) do |scenario|
      next unless scenario.valid?

      if count % 50 == 0
        puts "#{ Time.now } | #{ count } -> #{ scenario.id }"
      end

      begin
        vals = scenario.gql.query(gquery)

        scenario.update(user_values: scenario.user_values.merge(
          co2_emissions_of_imported_electricity_present: KG_PER_MJ_IN_G_PER_KWH *
            vals[0][1],
          co2_emissions_of_imported_electricity_future: KG_PER_MJ_IN_G_PER_KWH *
            vals[1][1]
        ))

      rescue StandardError => e
        puts e
      end

      count += 1
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
