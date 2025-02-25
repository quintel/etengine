class HouseholdsForecastingToEnum < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  INPUT = 'settings_enable_storage_optimisation_households_flexibility_p2p_electricity'

  def up
    migrate_scenarios do |scenario|
      next unless scenario.user_values.key? INPUT

      if scenario.user_values[INPUT] == 1.0
        scenario.user_values[INPUT] = 'optimizing_storage'
      else
        scenario.user_values[INPUT] = 'default'
      end
    end
  end

  def down
    migrate_scenarios do |scenario|
      next unless scenario.user_values.key? INPUT

      if %w[optimizing_storage optimizing_storage_households].include? scenario.user_values[INPUT]
        scenario.user_values[INPUT] = 1.0
      else
        scenario.user_values[INPUT] = 0.0
      end
    end
  end
end
