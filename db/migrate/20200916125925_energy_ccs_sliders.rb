require 'etengine/scenario_migration'

class EnergyCcsSliders < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration
  CCS_PLANTS = {
    energy_hydrogen_steam_methane_reformer: :energy_hydrogen_steam_methane_reformer_ccs,
    energy_power_combined_cycle_coal: :energy_power_combined_cycle_ccs_coal,
    energy_power_ultra_supercritical_lignite: :energy_power_ultra_supercritical_oxyfuel_ccs_lignite,
    energy_power_ultra_supercritical_coal: :energy_power_ultra_supercritical_ccs_coal,
    energy_power_combined_cycle_network_gas: :energy_power_combined_cycle_ccs_network_gas
  }
  def up
    migrate_scenarios do |scenario|
      # Check if CCS plant is set
      CCS_PLANTS.each do |regular_plant, ccs_plant|
        if scenario.user_values.key?("capacity_of_#{ccs_plant}")
          # Check if non-CCS counter part is set
          if scenario.user_values.key?("capacity_of_#{regular_plant}")
            non_ccs_value = scenario.user_values["capacity_of_#{regular_plant}"]
            ccs_value = scenario.user_values["capacity_of_#{ccs_plant}"]
            total_capacity = non_ccs_value + ccs_value
            # New slider reflects relative ratio between CCS and non-CCS plants
            if total_capacity > 0
              ccs_share = ccs_value / total_capacity
            else
              ccs_share = 0.0
            end
          else
            # If only CCS plant is set, new CCS slider will be 100%
            total_capacity = scenario.user_values["capacity_of_#{ccs_plant}"]
            ccs_share = 1.0
          end
          scenario.user_values["capacity_of_#{regular_plant}"] = total_capacity
          scenario.user_values["share_of_#{ccs_plant}"] = ccs_share
        end
      end
    end
  end
end

