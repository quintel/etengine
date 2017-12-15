class AddTransportMotorcycleUsingElectricityShareToUserValues < ActiveRecord::Migration
  def change
    count = 0
    scenarios = Scenario.where("`user_values` LIKE '%transport_motorcycle_using_gasoline_mix_share%'")

    puts "Need to migrate #{ scenarios.count } scenarios"

    scenarios.find_each do |scenario|
      values = scenario.user_values

      values['transport_motorcycle_using_electricity_share'] = 100 - values.fetch('transport_motorcycle_using_gasoline_mix_share')

      scenario.user_values = values
      scenario.save

      if count % 1000 == 0
        puts "I'm at position #{ count } (#{ scenario.id })"
      end

      count += 1
    end
  end
end
