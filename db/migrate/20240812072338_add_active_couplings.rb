require 'etengine/scenario_migration'

class AddActiveCouplings < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  INPUTS = Input.coupling_inputs_keys.freeze

  def up
    migrate_scenarios do |scenario|
      groups = coupled_groups(scenario)
      scenario.active_couplings = groups if groups.present?
    end
  end


  def coupled_groups(scenario)
    input_keys = scenario.user_values.keys + scenario.balanced_values.keys

    matches = INPUTS & input_keys

    matches.flat_map{ |input| Input.coupling_groups_for(input) }.uniq
  end
end
