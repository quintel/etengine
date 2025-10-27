require 'etengine/scenario_migration'

class TemperatureSetpointP2h < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios do |scenario|
      if scenario.user_values['capacity_of_energy_heat_flexibility_p2h_boiler_electricity'].to_f > 0 ||
         scenario.user_values['capacity_of_energy_heat_flexibility_p2h_heatpump_electricity'].to_f > 0
        scenario.user_values['temperature_cutoff_of_energy_flexibility_p2h'] = 30.0
      end
    end
  end
end
