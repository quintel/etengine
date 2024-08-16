class CrudeOilTransformation < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  OLD_EXTERNAL_COUPLING_DEMAND = external_coupling_industry_chemical_refineries_total_non_energetic

  OLD_EXTERNAL_COUPLING_OUTPUT_SHARES = %w[
    external_coupling_industry_chemical_refineries_transformation_crude_oil_output_share
    external_coupling_industry_chemical_refineries_transformation_diesel_output_share
    external_coupling_industry_chemical_refineries_transformation_gasoline_output_share
    external_coupling_industry_chemical_refineries_transformation_heavy_fuel_oil_output_share
    external_coupling_industry_chemical_refineries_transformation_kerosene_output_share
    external_coupling_industry_chemical_refineries_transformation_loss_output_share
    external_coupling_industry_chemical_refineries_transformation_lpg_output_share
    external_coupling_industry_chemical_refineries_transformation_refinery_gas_output_share
  ]

  NEW_EXTERNAL_COUPLING_DEMAND = external_coupling_industry_chemical_refineries_total_non_energetic

  NEW_EXTERNAL_COUPLING_INPUT_SHARES = %w[
    external_coupling_energy_chemical_other_transformation_external_coupling_node_ammonia_input_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_crude_oil_input_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_electricity_input_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_greengas_input_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_hydrogen_input_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_methanol_input_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_natural_gas_input_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_steam_hot_water_input_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_waste_mix_input_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_wood_pellets_input_share
  ]

  NEW_EXTERNAL_COUPLING_OUTPUT_SHARES = %w[
    external_coupling_energy_chemical_other_transformation_external_coupling_node_ammonia_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_crude_oil_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_diesel_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_gasoline_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_greengas_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_heavy_fuel_oil_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_hydrogen_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_kerosene_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_loss_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_lpg_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_methanol_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_natural_gas_output_share
  ]

  def up
    migrate_scenarios do |scenario|
      next unless Atlas::Dataset.exists?(scenario.area_code)
      dataset = Atlas::Dataset.find(scenario.area_code)

      set_present_demand(scenario, dataset) # Step 1: determine present_demand, determine future_demand, set present_demand based on future_demand
      assign_inputs(scenario)               # Step 2: assign inputs to NEW_EXTERNAL_COUPLING_INPUT_SHARES
      assign_outputs(scenario)              # Step 3: assign outputs to NEW_EXTERNAL_COUPLING_OUTPUT_SHARES
      delete_old_values(scenario)           # Step 4: delete old values

    end
  end

  private

  def set_present_demand(scenario, dataset)
    present_demand = dataset.get(:industry_refinery_transformation_crude_oil, :demand) # present_demand = present:V(industry_refinery_transformation_crude_oil,demand)
                                                                                       # |--> There is a chance this doesn't work in which case we may need to place this into a dataset JSON like the other examples
    raise "Present demand not found" unless present_demand.is_a?(Numeric)
    absolute_demand_change = scenario.user_values[OLD_EXTERNAL_COUPLING_DEMAND]        # absolute_demand_change = INPUT_VALUE(external_coupling_industry_chemical_refineries_total_non_energetic)
    future_demand = present_demand * absolute_demand_change / 100.0                    # future_demand = present_demand * absolute_demand_change / 100.0
    scenario.user_values[NEW_EXTERNAL_COUPLING_DEMAND] = future_demand                 # external_coupling_industry_chemical_refineries_total_non_energetic = future_demand
  end

  def assign_inputs(scenario)
    NEW_EXTERNAL_COUPLING_INPUT_SHARES.each do |key|                                   # for each key in NEW_EXTERNAL_COUPLING_INPUT_SHARES set it to 0, then set crude_oil_input_share to 100
      scenario.user_values[key] = 0.0
    end
    scenario.user_values[external_coupling_energy_chemical_other_transformation_external_coupling_node_crude_oil_input_share] = 100.0
  end

  def assign_outputs(scenario)
    NEW_EXTERNAL_COUPLING_OUTPUT_SHARES.each do |key|                                 # for each key in NEW_EXTERNAL_COUPLING_OUTPUT_SHARES set it to 0, then set some to their old values
      scenario.user_values[key] = 0.0
    end
    scenario.user_values[external_coupling_energy_chemical_other_transformation_external_coupling_node_crude_oil_output_share] = scenario.user_values[external_coupling_industry_chemical_refineries_transformation_crude_oil_output_share]
    scenario.user_values[external_coupling_energy_chemical_other_transformation_external_coupling_node_diesel_output_share] = scenario.user_values[external_coupling_industry_chemical_refineries_transformation_diesel_output_share]
    scenario.user_values[external_coupling_energy_chemical_other_transformation_external_coupling_node_gasoline_output_share] = scenario.user_values[external_coupling_industry_chemical_refineries_transformation_gasoline_output_share]
    scenario.user_values[external_coupling_energy_chemical_other_transformation_external_coupling_node_heavy_fuel_oil_output_share] = scenario.user_values[external_coupling_industry_chemical_refineries_transformation_heavy_fuel_oil_output_share]
    scenario.user_values[external_coupling_energy_chemical_other_transformation_external_coupling_node_kerosene_output_share] = scenario.user_values[external_coupling_industry_chemical_refineries_transformation_kerosene_output_share]
    scenario.user_values[external_coupling_energy_chemical_other_transformation_external_coupling_node_loss_output_share] = scenario.user_values[external_coupling_industry_chemical_refineries_transformation_refinery_gas_output_share] + scenario.user_values[external_coupling_industry_chemical_refineries_transformation_loss_output_share]
    scenario.user_values[external_coupling_energy_chemical_other_transformation_external_coupling_node_lpg_output_share] = scenario.user_values[external_coupling_industry_chemical_refineries_transformation_lpg_output_share]
  end

  def delete_old_values(scenario)
    scenario.user_values.delete(OLD_EXTERNAL_COUPLING_DEMAND)
    OLD_EXTERNAL_COUPLING_OUTPUT_SHARES.each do |key|
      scenario.user_values.delete(key)
    end
  end
end
