require 'etengine/scenario_migration'

class InsertHydrogenScenarioValues < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  def up
    scenario_values = JSON.load(File.read(
      Rails.root.join("tmp/scenario_values.json")
    ))

    migrate_scenarios do |scenario|
      next unless scenario_values.key?(scenario.id.to_s)

      new_inputs = scenario_values[scenario.id.to_s]

      new_inputs.each do |key, value|
        scenario.user_values[key] = value
      end
    end
  end
end
