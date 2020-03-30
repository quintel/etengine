require 'etengine/scenario_migration'

class UpdateCopCutoff < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  COP_CUTOFF_KEY = 'households_flexibility_space_heating_cop_cutoff'.freeze

  # The new defualt for cop cutoff is 2.6. However to retain the outcomes
  # of older scenarios, untouched cop cutoff values are set to the previous
  # default of 1.0

  def up
    migrate_scenarios do |scenario|
      next if scenario.user_values[COP_CUTOFF_KEY]

      scenario.user_values[COP_CUTOFF_KEY] = 1.0
    end
  end
end
