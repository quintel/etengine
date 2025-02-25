require 'etengine/scenario_migration'

class RenameCutoffCopInput < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  KEYS = {
    'flexibility_heat_pump_space_heating_cop_cutoff' => 'flexibility_heat_pump_space_heating_cop_cutoff_gas',
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
