require 'etengine/scenario_migration'

class RemoveFlhOfEnergyHydrogenWindTurbineOffshore < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # Retired key
  KEY = 'flh_of_energy_hydrogen_wind_turbine_offshore'.freeze

  # As part of setting the FLH of dedicated hydrogen offshore wind with 'regular' offshore wind input is
  # necessary to remove the input flh_of_energy_hydrogen_wind_turbine_offshore from existing scenarios. 
  def up
    migrate_scenarios do |scenario|

      # Check if the key is set, then remove it
      scenario.user_values.delete(KEY) if scenario.user_values.key?(KEY)
    end
  end
end
