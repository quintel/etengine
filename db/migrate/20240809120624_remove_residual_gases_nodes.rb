require 'etengine/scenario_migration'

class RemoveResidualGasesNodes < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  REPLACE_COUPLED_INPUTS = {
    'external_coupling_energy_chemical_other_transformation_external_coupling_node_total_demand' => %w[
      external_coupling_industry_residual_greengas
      external_coupling_industry_residual_natural_gas
      external_coupling_industry_residual_hydrogen
    ]
}.freeze

  # Mapping of output keys to their corresponding input keys
  CONVERSION_OUTPUT_MAPPING = {
    'external_coupling_energy_chemical_other_transformation_external_coupling_node_greengas_output_share' => 'external_coupling_industry_residual_greengas',
    'external_coupling_energy_chemical_other_transformation_external_coupling_node_natural_gas_output_share' => 'external_coupling_industry_residual_natural_gas',
    'external_coupling_energy_chemical_other_transformation_external_coupling_node_hydrogen_output_share' => 'external_coupling_industry_residual_hydrogen'
  }

  SET_CONVERSION_INPUT = 'external_coupling_energy_chemical_other_transformation_external_coupling_node_not_defined_input_share'

  SET_REMAINING_CONVERSION_SHARES = %w[
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
    external_coupling_energy_chemical_other_transformation_external_coupling_node_ammonia_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_crude_oil_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_diesel_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_gasoline_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_heavy_fuel_oil_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_kerosene_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_loss_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_lpg_output_share
    external_coupling_energy_chemical_other_transformation_external_coupling_node_methanol_output_share
  ].freeze


  def up
    migrate_scenarios do |scenario|
      # If the scenario was a coupled scenario, act on the coupling sliders.
      next unless scenario.coupled?

      set_conversion_outputs(scenario)
      replace_coupled_shares(scenario)

    end
  end


  # This method replaces a set of "old" input shares in the scenario with a new combined share.
  # It iterates through a predefined set of new keys and corresponding old keys, aggregates the
  # values from the old keys, and assigns the sum to the new key in the scenario's user_values.

  def replace_coupled_shares(scenario)
    # Iterate over each pair of new_key and old_keys in the REPLACE_COUPLED_INPUTS hash.
    REPLACE_COUPLED_INPUTS.each do |new_key, old_keys|
      was_set = false  # Flag to check if any of the old keys were set.

      # Calculate the new share by summing up the values of the old keys.
      new_share = old_keys.reduce(0.0) do |sum, old_key|
        # Check if the old key has a value in the scenario.
        was_set = true if scenario.user_values.key? old_key

        # Add the value of the old key to the sum, or 0 if the key does not exist.
        sum += scenario.user_values.delete(old_key) || 0
      end

      # If any of the old keys were set, assign the calculated sum to the new key.
      scenario.user_values[new_key] = new_share if was_set
    end
  end


  def set_conversion_outputs(scenario)
    # Calculate the total demand
    total_demand = REPLACE_COUPLED_INPUTS['external_coupling_energy_chemical_other_transformation_external_coupling_node_total_demand'].sum do |old_key|
      scenario.user_values[old_key] || 0
    end

    # Iterate over the output mapping and set the output shares
    CONVERSION_OUTPUT_MAPPING.each do |output, input|
      input_value = scenario.user_values[input] || 0
      scenario.user_values[output] = total_demand.zero? ? 0 : input_value / total_demand * 100.0
    end

    # Finish if total_demand is zero
    return if total_demand.zero?

    # Set not_defined input carrier to 1.0 and other conversion shares to zero if total_demand > 0
    scenario.user_values[SET_CONVERSION_INPUT] = 100.0
    SET_REMAINING_CONVERSION_SHARES.each do |key|
      scenario.user_values[key] = 0.0
    end

  end

end
