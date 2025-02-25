require 'etengine/scenario_migration'

# The full load hours of the SMR have been updated from 7500 to 8322. For 7500 was no source in
# ETDataset and the 8322 is based on this datasheet
#
# This migration scales SMRs in existing scenarios to account for the change.
#
# See https://github.com/quintel/etengine/issues/1292
class UpdateSmrCapacity < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  def up
    do_migrate(7500.0 / 8322.0)
  end

  def down
    do_migrate(8322.0 / 7500.0)
  end

  private

  def do_migrate(multiplier)
    migrate_scenarios do |scenario|
      if scenario.user_values.key?(:capacity_of_energy_hydrogen_steam_methane_reformer)
        scenario.user_values[:capacity_of_energy_hydrogen_steam_methane_reformer] *= multiplier
      end
    end
  end
end
