require 'etengine/scenario_migration'

class RenameGasPlantInputs < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  KEYS = {
    'capacity_of_energy_power_combined_cycle_network_gas' => 'capacity_of_energy_power_combined_cycle_network_gas_dispatchable',
    'capacity_of_energy_power_turbine_network_gas' => 'capacity_of_energy_power_turbine_network_gas_dispatchable',
    'share_of_energy_power_combined_cycle_ccs_network_gas' => 'share_of_energy_power_combined_cycle_ccs_network_gas_dispatchable'
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
