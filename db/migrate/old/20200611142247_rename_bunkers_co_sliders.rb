require 'etengine/scenario_migration'

class RenameBunkersCoSliders < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  INPUTS = {
    flexibility_p2l_point_source_CO2: :flexibility_p2l_point_source_co2,
    flexibility_p2l_point_source_CO: :flexibility_p2l_point_source_co
  }

  def up
    migrate_scenarios do |scenario|
      update_scenario(scenario, INPUTS)
    end
  end

  def down
    inverted_inputs = INPUTS.invert

    migrate_scenarios do |scenario|
      update_scenario(scenario, inverted_inputs)
    end
  end

  private

  def update_scenario(scenario, inputs)
    inputs.each do |from, to|
      next unless scenario.user_values.key?(from)

      scenario.user_values[to] = scenario.user_values.delete(from)
    end

  end
end
