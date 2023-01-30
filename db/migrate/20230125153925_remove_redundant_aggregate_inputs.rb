require 'etengine/scenario_migration'

class RemoveRedundantAggregateInputs < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  REDUNDANT_AGGREGATE_KEYS = %w[
    industry_useful_demand_for_chemical_aggregated_industry
    industry_useful_demand_for_chemical_aggregated_industry_electricity_efficiency
    industry_useful_demand_for_chemical_aggregated_industry_useable_heat_efficiency
  ].freeze


  def up
    migrate_scenarios(since: Date.new(2022, 1, 1)) do |scenario|
      REDUNDANT_AGGREGATE_KEYS.each do |key|
        scenario.user_values.delete(key) if scenario.user_values.include? key
      end
    end
  end
end
