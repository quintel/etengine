# frozen_string_literal: true

class RemoveMicroChpInput < ActiveRecord::Migration[5.1]
  SOURCE_KEY = 'households_heater_micro_chp_network_gas_share'
  TARGET_KEY = 'households_heater_combined_network_gas_share'

  def up
    say "#{Scenario.migratable.count} scenarios to be checked..."
    updated = 0

    Scenario.migratable.find_each.with_index do |scenario, index|
      say "#{index} done" if index.positive? && (index % 250).zero?

      if collection_name(scenario, SOURCE_KEY) && collection_name(scenario, TARGET_KEY)
        updated += 1

        source_collection = scenario.public_send(collection_name(scenario, SOURCE_KEY))
        target_collection = scenario.public_send(collection_name(scenario, TARGET_KEY))

        target_collection[TARGET_KEY] += source_collection[SOURCE_KEY]
        source_collection.delete(SOURCE_KEY)

        scenario.save(validate: false, touch: false)
      end
    end

    say "Finished. Updated #{updated} scenarios."
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def collection_name(scenario, input)
    if scenario.user_values[input]
      :user_values
    elsif scenario.balanced_values[input]
      :balanced_values
    end
  end
end
