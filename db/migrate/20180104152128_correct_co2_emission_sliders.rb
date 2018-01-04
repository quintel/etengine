class CorrectCo2EmissionSliders < ActiveRecord::Migration
  KG_PER_MJ_IN_G_PER_KWH = 3600.0

  def change
    scenarios = Scenario.where(
      '(protected = ? OR created_at >= ?) AND source != ? AND title != ?',
      true, 1.month.ago, 'Mechanical Turk', 'test'
    ).order(:area_code)

    count = 0
    puts "Need to migrate: #{ scenarios.count } scenarios"

    scenarios.find_each do |scenario|
      next unless scenario.valid?

      if count % 50 == 0
        puts "#{ Time.now } | #{ count } -> #{ scenario.id }"
      end

      gql = scenario.gql

      scenario.user_values.merge!(
        co2_emissions_of_imported_electricity_present: KG_PER_MJ_IN_G_PER_KWH *
          gql.present.query(:average_co2_emissions_of_produced_electricity),
        co2_emissions_of_imported_electricity_future: KG_PER_MJ_IN_G_PER_KWH *
          gql.future.query(:average_co2_emissions_of_produced_electricity)
      )

      scenario.save

      count += 1
    end
  end
end
