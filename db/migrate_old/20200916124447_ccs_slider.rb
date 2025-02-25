require 'etengine/scenario_migration'

class CcsSlider < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration
  NEW_INDUSTRY_INPUTS = %w[
      share_of_industry_chemicals_fertilizers_captured_combustion_co2
      share_of_industry_steel_captured_co2
      share_of_industry_other_paper_captured_co2
      share_of_industry_other_food_captured_co2
      share_of_industry_chemicals_fertilizers_captured_processes_co2
  ].freeze

  def up
    migrate_scenarios do |scenario|
      if scenario.user_values.key?('industry_ccs_in_industry')
         old_value = scenario.user_values['industry_ccs_in_industry']
         NEW_INDUSTRY_INPUTS.each do |key|
         scenario.user_values[key] = old_value
        end
      end
    end
  end
end
