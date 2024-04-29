require 'etengine/scenario_migration'

class FixNanHydrogenShares < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  POSSIBLE_NAN_SHARES = %w[
    share_of_energy_hydrogen_steam_methane_reformer_ccs_must_run
    share_of_energy_hydrogen_autothermal_reformer_ccs_must_run
    share_of_energy_hydrogen_biomass_gasification_ccs
  ]

  def up
    migrate_scenarios do |scenario|
      POSSIBLE_NAN_SHARES.each do |share|
        next unless scenario.user_values.key?(share)

        scenario.user_values.delete(share) if scenario.user_values[share].nan?
      end
    end
  end
end
