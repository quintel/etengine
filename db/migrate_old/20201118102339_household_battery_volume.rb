require 'etengine/scenario_migration'

class HouseholdBatteryVolume < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration
  P2P_KEY = "households_flexibility_p2p_electricity_market_penetration"
  # old volume divided by new volume
  ADJUSTMENT_FACTOR = 0.0198 / 0.0097

  def up
    migrate_scenarios do |scenario|
      if scenario.user_values.key?(P2P_KEY)
        new_value = scenario.user_values[P2P_KEY] * ADJUSTMENT_FACTOR
        if new_value > 100.0
          new_value = 100.0
        end
        scenario.user_values[P2P_KEY] = new_value
      end
    end
  end
end
