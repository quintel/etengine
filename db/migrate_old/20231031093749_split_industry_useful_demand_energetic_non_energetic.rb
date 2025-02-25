# frozen_string_literal: true

require 'etengine/scenario_migration'

SET_KEYS = %w[
  industry_useful_demand_for_aggregated_other
  industry_aggregated_other_industry_coal_share
  industry_aggregated_other_industry_crude_oil_share
  industry_aggregated_other_industry_hydrogen_share
  industry_aggregated_other_industry_network_gas_share
  industry_aggregated_other_industry_wood_pellets_share
]

# Adds energetic and non_energetic input values for the
# inputs listed above.
#
# See https://github.com/quintel/etmodel/issues/4116
class SplitIndustryUsefulDemandEnergeticNonEnergetic < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  def change
    migrate_scenarios do |scenario|
      # Quickly check if any of the keys is set in the scenario (intersect)
      intersect_keys = scenario.user_values.keys & SET_KEYS
      next if intersect_keys.empty?

      # Loop over the keys for which a value was set
      intersect_keys.each do |key|

        next if scenario.user_values[key].blank?

        case
        when key.include?('useful_demand')
          scenario.user_values["#{key}_energetic"] = scenario.user_values[key]
          scenario.user_values["#{key}_non_energetic"] = scenario.user_values[key]
        when key.include?('coal')
          scenario.user_values["#{key}_energetic"] = scenario.user_values[key]
          scenario.user_values['industry_aggregated_other_industry_cokes_share_energetic'] = 0
        when key.include?('hydrogen')
          scenario.user_values["#{key}_energetic"] = scenario.user_values[key]
          scenario.user_values['industry_aggregated_other_industry_hydrogen_share_non_energetic'] = 0
        else
          scenario.user_values["#{key}_energetic"] = scenario.user_values[key]
        end

        scenario.user_values.delete(key)
      end
    end
  end
end
