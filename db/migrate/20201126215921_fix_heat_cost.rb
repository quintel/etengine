require 'etengine/scenario_migration'

class FixHeatCost < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration
  INDOOR_KEY = "costs_heat_infra_indoors"
  OUTDOOR_KEY = "costs_heat_infra_outdoors"

  def up
    migrate_scenarios do |scenario|
      if scenario.user_values[INDOOR_KEY] == 0.8
        scenario.user_values[INDOOR_KEY] = 80.0
      end

      if scenario.user_values[OUTDOOR_KEY] == 0.8
        scenario.user_values[OUTDOOR_KEY] = 80.0
      end
    end
  end
end
