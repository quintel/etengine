require 'etengine/scenario_migration'

class SteelInputs < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  KEYS = {
    "industry_steel_blastfurnace_current_consumption_useable_heat_share" => "industry_steel_blastfurnace_bof_share",
    "industry_steel_electricfurnace_electricity_share" => "industry_steel_scrap_hbi_eaf_share",
    "industry_steel_hisarna_consumption_useable_heat_share" => "industry_steel_cyclonefurnace_bof_share"
  }.freeze

  def up
    # Retrieve BAT input value
    migrate_scenarios do |scenario|
      if scenario.user_values.key?('industry_steel_blastfurnace_bat_consumption_useable_heat_share')
        bat = scenario.user_values['industry_steel_blastfurnace_bat_consumption_useable_heat_share']
        scenario.user_values.delete('industry_steel_blastfurnace_bat_consumption_useable_heat_share')
      else
        bat = 0.0
      end
      # Add BAT value to BF current input. BAT has been removed, only BF current remains
      if scenario.user_values.key?('industry_steel_blastfurnace_current_consumption_useable_heat_share')
        scenario.user_values['industry_steel_blastfurnace_current_consumption_useable_heat_share'] += bat
      end
      # Rename inputs
      KEYS.each do |old, new|
        if scenario.user_values.key?(old)
          scenario.user_values[new] =
          scenario.user_values.delete(old)
        end
      end
    end
  end
end
