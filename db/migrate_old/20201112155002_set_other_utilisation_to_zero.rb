require 'etengine/scenario_migration'

class SetOtherUtilisationToZero < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios do |scenario|
      # Set other utilisation to zero. This is a new input. In some areas it
      # has a non-zero default value. This could result in unintended 'other use'
      # of captured CO2 in the future.
      scenario.user_values["demand_of_molecules_other_utilisation_co2"] = 0.0
    end
  end
end
