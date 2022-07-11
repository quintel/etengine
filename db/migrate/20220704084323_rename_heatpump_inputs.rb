require 'etengine/scenario_migration'

class RenameHeatpumpInputs < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  KEYS = {
    'buildings_heater_hybrid_heatpump_air_water_electricity_share' => 'buildings_space_heater_hybrid_heatpump_air_water_electricity_share',
    'households_flexibility_space_heating_cop_cutoff' => 'flexibility_heat_pump_space_heating_cop_cutoff',
    'households_flexibility_water_heating_cop_cutoff' => 'flexibility_heat_pump_water_heating_cop_cutoff'
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
