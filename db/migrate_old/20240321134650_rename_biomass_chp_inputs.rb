require 'etengine/scenario_migration'

class RenameBiomassChpInputs < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  KEYS = {
    'capacity_of_energy_chp_local_wood_pellets' => 'capacity_of_energy_chp_local_wood_pellets_dispatchable',
    'share_of_energy_chp_local_ht_wood_pellets' => 'share_of_energy_chp_local_ht_wood_pellets_dispatchable',
    'share_of_energy_chp_local_mt_wood_pellets' => 'share_of_energy_chp_local_mt_wood_pellets_dispatchable'
  }.freeze

  def up
    migrate_scenarios do |scenario|
      KEYS.each do |old_key, new_key|
        if scenario.user_values.key?(old_key)
          scenario.user_values[new_key] = scenario.user_values.delete(old_key)
        end
      end
    end
  end
end
