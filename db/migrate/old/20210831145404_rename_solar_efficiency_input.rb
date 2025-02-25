require 'etengine/scenario_migration'

class RenameSolarEfficiencyInput < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios do |scenario|
      next unless scenario.user_values.key?("technical_solar_pv_efficiency")
      scenario.user_values["efficiency_energy_power_solar_pv_solar_radiation"] = scenario.user_values.delete("technical_solar_pv_efficiency")
    end
  end

  def down
    migrate_scenarios do |scenario|
      next unless scenario.user_values.key?("efficiency_energy_power_solar_pv_solar_radiation")
      scenario.user_values["technical_solar_pv_efficiency"] = scenario.user_values.delete("efficiency_energy_power_solar_pv_solar_radiation")
    end
  end

end
