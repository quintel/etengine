require 'etengine/scenario_migration'

class AddActiveCouplings < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios do |scenario|
      scenario.inactive_couplings.each { |coupling| scenario.activate_coupling(coupling)}
    end
  end

  def down;end
end
