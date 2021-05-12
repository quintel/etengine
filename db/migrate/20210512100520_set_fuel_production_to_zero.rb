require 'etengine/scenario_migration'

class SetFuelProductionToZero < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration
  def up
    migrate_scenarios do |scenario|
      # Set fuel production of primary carriers to zero. These are new inputs. In some areas it
      # had a non-zero default value due to the time_curves (which are now removed). This migration
      # could result in a different import / export balance in scenarios.
      scenario.user_values["fuel_production_coal"] = 0.0
      scenario.user_values["fuel_production_crude_oil"] = 0.0
      scenario.user_values["fuel_production_lignite"] = 0.0
      scenario.user_values["fuel_production_natural_gas"] = 0.0
      scenario.user_values["fuel_production_uranium_oxide"] = 0.0
    end
  end
end