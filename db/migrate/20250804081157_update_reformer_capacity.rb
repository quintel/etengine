require 'etengine/scenario_migration'

# The full load hours of ammonia reformers and Liquid H2 regasifiers have been updated from 4690 to 7884.
#
# This migration scales ammonia reformers and Liquid H2 regasifiers in existing scenarios to account for the change.
#

class UpdateReformerCapacity < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration


  def do_migrate()
    migrate_scenarios do |scenario|
      if scenario.user_values.key?('capacity_of_energy_hydrogen_lohc_reformer')
        scenario.user_values['capacity_of_energy_hydrogen_lohc_reformer'] *= (4690.0 / 7884.0)
      end
      if scenario.user_values.key?('capacity_of_energy_hydrogen_liquid_hydrogen_regasifier')
        scenario.user_values['capacity_of_energy_hydrogen_liquid_hydrogen_regasifier'] *= (4690.0 / 7884.0)
      end
    end
  end

  def up
    do_migrate()
  end
end
