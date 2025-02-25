require 'etengine/scenario_migration'

class LoadshiftingInputOutputCapacity < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  LOAD_SHIFTING_PAIRS = [
    %w[
      capacity_of_industry_chemical_flexibility_load_shifting_electricity
      input_capacity_of_industry_chemical_flexibility_load_shifting_electricity
    ], %w[
      capacity_of_industry_metal_flexibility_load_shifting_electricity
      input_capacity_of_industry_metal_flexibility_load_shifting_electricity
    ], %w[
      capacity_of_industry_other_flexibility_load_shifting_electricity
      input_capacity_of_industry_other_flexibility_load_shifting_electricity
    ], %w[
      capacity_of_industry_other_ict_flexibility_load_shifting_electricity
      input_capacity_of_industry_other_ict_flexibility_load_shifting_electricity
    ]
  ]

  def up
    migrate_scenarios do |scenario|
      LOAD_SHIFTING_PAIRS.each do |original_capacity, input_capacity|
        next unless scenario.user_values.key? original_capacity

        scenario.user_values[input_capacity] = scenario.user_values[original_capacity]
      end
    end
  end
end
