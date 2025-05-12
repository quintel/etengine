require 'etengine/scenario_migration'

class MergeHouseholdAppliancesEfficiency < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  NEW_INPUT = 'households_appliances_electricity_efficiency'.freeze

  OLD_INPUTS = %w[
    households_appliances_clothes_dryer_electricity_efficiency
    households_appliances_computer_media_electricity_efficiency
    households_appliances_dishwasher_electricity_efficiency
    households_appliances_fridge_freezer_electricity_efficiency
    households_appliances_other_electricity_efficiency
    households_appliances_television_electricity_efficiency
    households_appliances_vacuum_cleaner_electricity_efficiency
    households_appliances_washing_machine_electricity_efficiency
  ].freeze

  PARENT_SHARES = %w[
    households_final_demand_for_appliances_electricity__households_appliances_clothes_dryer_electricity__electricity_parent_share
    households_final_demand_for_appliances_electricity__households_appliances_computer_media_electricity__electricity_parent_share
    households_final_demand_for_appliances_electricity__households_appliances_dishwasher_electricity__electricity_parent_share
    households_final_demand_for_appliances_electricity__households_appliances_fridge_freezer_electricity__electricity_parent_share
    households_final_demand_for_appliances_electricity__households_appliances_other_electricity__electricity_parent_share
    households_final_demand_for_appliances_electricity__households_appliances_television_electricity__electricity_parent_share
    households_final_demand_for_appliances_electricity__households_appliances_vacuum_cleaner_electricity__electricity_parent_share
    households_final_demand_for_appliances_electricity__households_appliances_washing_machine_electricity__electricity_parent_share
  ].freeze

  def up
    migrate_scenarios do |scenario|
      unless relevant_inputs_set?(scenario)
        puts "Skipping scenario #{scenario.id}: no relevant old inputs set."
        next
      end
  
      puts "Migrating scenario #{scenario.id}: relevant old inputs found."
  
      new_efficiency = calculate_new_efficiency(scenario)
  
      puts "Calculated new efficiency for scenario #{scenario.id}: #{new_efficiency.inspect}"
  
      if new_efficiency
        scenario.user_values[NEW_INPUT] = new_efficiency
        true
      else
        FileUtils.mkdir_p("tmp") # Make sure tmp/ exists
        File.open("tmp/dataset_dump_#{scenario.id}.txt", "w") do |file|
          file.puts "Dataset values for scenario #{scenario.id}:"
          scenario.area.dataset.each do |key, value|
            file.puts "#{key}: #{value.inspect}"
          end
        end
        nil
      end
    end
  end
  private

  def relevant_inputs_set?(scenario)
    OLD_INPUTS.any? { |key| scenario.user_values[key].present? }
  end

  def calculate_new_efficiency(scenario)
    weighted_sum = 0.0
    total_share = 0.0

    OLD_INPUTS.each_with_index do |input_key, index|
      input_value = scenario.user_values[input_key]
      parent_share_value = scenario.area[PARENT_SHARES[index]] || 0.0
      puts "Checking input_key: #{input_key} with parent_share_key: #{PARENT_SHARES[index]}"
      puts "  => input_value: #{input_value.inspect}, parent_share_value: #{parent_share_value.inspect}"
      next unless input_value && parent_share_value

      weighted_sum += parent_share_value * (1.0 - (input_value / 100.0))
      total_share += parent_share_value
    end

    return nil unless total_share.positive?

    (1.0 - (weighted_sum / total_share)) * 100.0
  end
end