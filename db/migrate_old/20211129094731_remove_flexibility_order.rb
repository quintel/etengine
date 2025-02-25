require 'etengine/scenario_migration'

class RemoveFlexibilityOrder < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  INPUT_DEFAULTS = {
    wtp_of_energy_hydrogen_flexibility_p2g_electricity: 0.4,
    wtp_of_energy_flexibility_hv_opac_electricity: 0.6,
    wtp_of_energy_flexibility_mv_batteries_electricity: 0.8,
    wtp_of_energy_flexibility_pumped_storage_electricity: 0.5,
    wtp_of_energy_heat_flexibility_p2h_boiler_electricity: 0.2,
    wtp_of_energy_heat_flexibility_p2h_heatpump_electricity: 0.1,
    wtp_of_households_flexibility_p2p_electricity: 0.9,
    wtp_of_transport_car_flexibility_p2p_electricity: 0.7,
    wtp_of_industry_other_paper_flexibility_p2h_electricity: 0.3,
    wtp_of_industry_chemicals_other_flexibility_p2h_electricity: 0.3,
    wtp_of_industry_chemicals_refineries_flexibility_p2h_electricity: 0.3,
    wtp_of_industry_other_food_flexibility_p2h_electricity: 0.3,
  }.freeze

  EURO_MW_STEP = 0.1
  DEFAULT_WHEN_ORDER_SET = 0.1

  INPUTS_MAP = {
    'power_to_gas' => :wtp_of_energy_hydrogen_flexibility_p2g_electricity,
    'opac' => :wtp_of_energy_flexibility_hv_opac_electricity,
    'mv_batteries' => :wtp_of_energy_flexibility_mv_batteries_electricity,
    'pumped_storage' => :wtp_of_energy_flexibility_pumped_storage_electricity,
    'power_to_heat_district_heating_boiler' => :wtp_of_energy_heat_flexibility_p2h_boiler_electricity,
    'power_to_heat_district_heating_heatpump' => :wtp_of_energy_heat_flexibility_p2h_heatpump_electricity,
    'household_batteries' => :wtp_of_households_flexibility_p2p_electricity,
    'electric_vehicle' => :wtp_of_transport_car_flexibility_p2p_electricity,
    'power_to_heat_industry' => [
      :wtp_of_industry_other_paper_flexibility_p2h_electricity,
      :wtp_of_industry_chemicals_other_flexibility_p2h_electricity,
      :wtp_of_industry_chemicals_refineries_flexibility_p2h_electricity,
      :wtp_of_industry_other_food_flexibility_p2h_electricity
    ]
  }.freeze

  BATTERY_WTA = {
    wta_of_energy_flexibility_hv_opac_electricity: 1.6,
    wta_of_energy_flexibility_mv_batteries_electricity: 1.8,
    wta_of_energy_flexibility_pumped_storage_electricity: 1.5,
    wta_of_households_flexibility_p2p_electricity: 1.9,
    wta_of_transport_car_flexibility_p2p_electricity: 1.7,
  }.freeze

  def up
    # Get all flexibility orders from the db, as the AR model has already been removed
    flex_order_records = ActiveRecord::Base.connection.execute('SELECT * FROM flexibility_orders')

    # Convert the db entries to something we can work with
    scenarios_with_flex_order = flex_order_records.to_h do |record|
      scenario_id = record[1]
      [scenario_id, convert_to_inputs(record[2])]
    end

    # Update inputs
    migrate_scenarios do |scenario|
      BATTERY_WTA.each do |input, value|
        scenario.user_values[input] = value
      end

      if scenarios_with_flex_order.key?(scenario.id)
        scenario.user_values.update(scenarios_with_flex_order[scenario.id])
      else
        scenario.user_values.update(INPUT_DEFAULTS)
      end
    end

    # Remove db table
    drop_table :flexibility_orders
  end

  # No going back from here
  def down
    ActiveRecord::IrreversibleMigration
  end

  # Calculate the new Euro/MW value for each specified flex option from a raw flexibility order.
  # Decrease the amount of Euro/MW by EURO_MW_STEP for each lower option in the order.
  # Missing options are filled up with a default value.
  #
  # Returns a Hash [input_name, value] that can be directly used to update user_values
  def convert_to_inputs(raw_order)
    return INPUT_DEFAULTS unless raw_order

    flexibility_order = raw_order.tr('- ', '').split("\n").drop(1)
    inputs = calculate_prices(flexibility_order)

    missing_options(flexibility_order).each do |option|
      inputs[option] = DEFAULT_WHEN_ORDER_SET
    end

    inputs
  end

  # Returns a Hash with input_names and their new value.
  # Decrease the amount of Euro/MW by EURO_MW_STEP for each lower option in the order
  # with a minimum of EURO_MW_STEP.
  #
  # Returns a Hash [input_name, value] based on the options in the flexibility order
  def calculate_prices(flexibility_order)
    flexibility_order.delete('export')

    euro_mw = flexibility_order.length * EURO_MW_STEP

    flexibility_order.each_with_object({}) do |flex_option, inputs|
      if INPUTS_MAP[flex_option].is_a?(Array)
        INPUTS_MAP[flex_option].each { |option| inputs[option] = euro_mw.round(1) }
      else
        inputs[INPUTS_MAP[flex_option]] = euro_mw.round(1)
      end

      euro_mw -= EURO_MW_STEP
    end
  end

  def missing_options(flexibility_order)
    INPUTS_MAP.keys - flexibility_order
  end
end
