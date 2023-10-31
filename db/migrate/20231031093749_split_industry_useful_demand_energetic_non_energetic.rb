# frozen_string_literal: true

require 'etengine/scenario_migration'

# Renames industry_useful_demand_for_aggregated_other to '...energetic'
# and adds a non-energetic input with the same value
#
# See https://github.com/quintel/etmodel/issues/4116
class SplitIndustryUsefulDemandEnergeticNonEnergetic < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  old_key   = 'industry_useful_demand_for_aggregated_other'
  new_key_1 = 'industry_useful_demand_for_aggregated_other_energetic'
  new_key_1 = 'industry_useful_demand_for_aggregated_other_non_energetic'

  def change
    migrate_scenarios do |scenario|
      if scenario.user_values[old_key].present?
        scenario.user_values[new_key_1] = scenario.user_values[old_key]
        scenario.user_values[new_key_2] = scenario.user_values[old_key]
      end
    end
  end
end
