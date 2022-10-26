require 'etengine/scenario_migration'

class RenameAmmoniaShareInputs < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios do |scenario|
      rename_input(
        scenario,
        'industry_chemicals_fertilizers_steam_methane_reformer_hydrogen_share',
        'industry_chemicals_fertilizers_local_ammonia_local_hydrogen_share'
      )

      rename_input(
        scenario,
        'industry_chemicals_fertilizers_hydrogen_network_share',
        'industry_chemicals_fertilizers_local_ammonia_central_hydrogen_share'
      )

      if scenario.user_values.key?('industry_chemicals_fertilizers_local_ammonia_central_hydrogen_share') ||
          scenario.user_values.key?('industry_chemicals_fertilizers_local_ammonia_local_hydrogen_share')
        scenario.user_values['industry_chemicals_fertilizers_central_ammonia_share'] = 0.0
      end
    end
  end

  def down
    migrate_scenarios do |scenario|
      rename_input(
        scenario,
        'industry_chemicals_fertilizers_local_ammonia_local_hydrogen_share',
        'industry_chemicals_fertilizers_steam_methane_reformer_hydrogen_share'
      )

      rename_input(
        scenario,
        'industry_chemicals_fertilizers_local_ammonia_central_hydrogen_share',
        'industry_chemicals_fertilizers_hydrogen_network_share'
      )

      scenario.user_values.delete('industry_chemicals_fertilizers_central_ammonia_share')
    end
  end

  private

  def rename_input(scenario, from, to)
    if scenario.user_values.key?(from)
      scenario.user_values[to] = scenario.user_values.delete(from)
    end
  end
end
