require 'etengine/scenario_migration'

class MergeHouseholdAppliancesEfficiency < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  NEW_INPUT = 'households_appliances_electricity_efficiency'.freeze

  # Parent shares mapped to corresponding inputs
  SHARE_MAP = {
    households_appliances_clothes_dryer_electricity:  'households_appliances_clothes_dryer_electricity_efficiency',
    households_appliances_computer_media_electricity: 'households_appliances_computer_media_electricity_efficiency',
    households_appliances_dishwasher_electricity:     'households_appliances_dishwasher_electricity_efficiency',
    households_appliances_fridge_freezer_electricity: 'households_appliances_fridge_freezer_electricity_efficiency',
    households_appliances_other_electricity:          'households_appliances_other_electricity_efficiency',
    households_appliances_television_electricity:     'households_appliances_television_electricity_efficiency',
    households_appliances_vacuum_cleaner_electricity: 'households_appliances_vacuum_cleaner_electricity_efficiency',
    households_appliances_washing_machine_electricity:'households_appliances_washing_machine_electricity_efficiency'
  }.freeze

  def up
    migrate_scenarios do |scenario|
      next unless SHARE_MAP.values.any? { |key| scenario.user_values.key?(key) }

      # Skip if the dataset itself can't be found
      dataset = begin
        Atlas::Dataset.find(scenario.area_code)
      rescue Atlas::DocumentNotFoundError, Atlas::DatasetError
        next
      end

      parent_shares = dataset.shares("energy/residences_final_demand_for_appliances_electricity_parent_share")

      # Calculate weighted avg. Start value for the old sliders was 0.0. If input is not set, it's treated as 0.0.
      weighted_avg = SHARE_MAP.sum(0.0) do |parent_share_key, input_key|
        efficiency = scenario.user_values.fetch(input_key, 0.0)
        parent_shares.get(parent_share_key) * (1 - efficiency / 100.0)
      end

      # The weighted average is reconverted into a percentage
      new_input = (1 - weighted_avg) * 100.0

      # The slider values should be checked for their minimum and maximum values
      scenario.user_values[NEW_INPUT] = [[new_input, 90.0].min, -90.0].max
    end
  end
end
