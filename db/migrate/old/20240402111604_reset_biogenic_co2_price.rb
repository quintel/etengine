require 'etengine/scenario_migration'

class ResetBiogenicCo2Price < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  BIOGENIC_CO2_PRICE = 'costs_captured_biogenic_co2'.freeze

  # The default for the new captured biogenic CO2 price is equal to CO2 emissions
  # price. However to retain the outcomes of older scenarios, the biogenic CO2 price
  # is set to 0.

  def up
    migrate_scenarios do |scenario|
      next if scenario.user_values.key?(BIOGENIC_CO2_PRICE)

      scenario.user_values[BIOGENIC_CO2_PRICE] = 0.0
    end
  end
end
