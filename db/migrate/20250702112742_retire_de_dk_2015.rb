require 'etengine/scenario_migration'

class RetireDeDk2015 < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios do |scenario|
      next unless ['de', 'dk'].include?(scenario.area_code)

      if scenario.area_code == 'de'
        scenario.area_code = 'DE_germany'
      elsif scenario.area_code == 'dk'
        scenario.area_code = 'DK_denmark'
      end
    end
  end
end
