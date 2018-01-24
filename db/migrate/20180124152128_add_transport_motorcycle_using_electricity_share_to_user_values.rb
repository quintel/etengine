class AddTransportMotorcycleUsingElectricityShareToUserValues < ActiveRecord::Migration[5.1]
  def change
    count = 0
    scenarios = Scenario.where(
      '(protected = ? OR created_at >= ?) AND source != ? AND title != ?',
      true, 1.month.ago, 'Mechanical Turk', 'test'
    ).where("`user_values` LIKE '%transport_motorcycle_using_gasoline_mix_share%'")
    .where("`user_values` NOT LIKE '%transport_motorcycle_using_electricity_share%'")

    puts "Need to migrate #{ scenarios.count } scenarios"

    scenarios.find_each(batch_size: 5) do |s|
      s.update(user_values: s.user_values.merge(
        transport_motorcycle_using_electricity_share: 100 -
          s.user_values.fetch('transport_motorcycle_using_gasoline_mix_share')
      ))

      if count % 100 == 0
        puts "I'm at position #{ count } (#{ s.id })"
      end

      count += 1
    end
  end
end
