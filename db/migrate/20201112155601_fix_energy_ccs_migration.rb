require 'etengine/scenario_migration'

class FixEnergyCcsMigration < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration
  INPUTS = [
      'share_of_energy_power_combined_cycle_ccs_network_gas',
      'share_of_energy_power_ultra_supercritical_ccs_coal',
      'share_of_energy_power_ultra_supercritical_oxyfuel_ccs_lignite',
      'share_of_energy_power_combined_cycle_ccs_coal',
      'share_of_energy_hydrogen_steam_methane_reformer_ccs'
  ].freeze

  def up
    migrate_scenarios do |scenario|
      INPUTS.each do |ccs_input|
        if scenario.user_values.key?(ccs_input)
          value = scenario.user_values[ccs_input]

          if value > 0 && value <= 1.0
            scenario.user_values[ccs_input] *= 100.0
          end
        end
      end
    end
  end
end
