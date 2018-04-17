class MigrateHydrogenTransport < ActiveRecord::Migration[5.1]
  def up
    # Remove 'power_to_gas' from the flexibility order
    #
    FlexibilityOrder.find_in_batches.with_index do |group, batch|
      group.each do |order|
        new_order = order.order
        new_order.delete('power_to_gas')

        order.order = new_order
        order.save
      end
    end

    # Migrate scenarios
    #
    data = JSON.parse(
      File.read(
        Rails.root.join(
          'db',
          'migrate',
          '20180417090256_migrate_hydrogen_transport',
          "data.#{ Rails.env }.json"
        )
      )
    )

    data.each_pair do |scenario_id, changes|
      scenario = Scenario.find(scenario_id)
      scenario.user_values = scenario.user_values.merge(changes)
      scenario.save(validate: false)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
