class CrudeOilTransformation < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  OLD_EXTERNAL_COUPLING_DEMAND = 'external_coupling_industry_chemical_refineries_total_non_energetic'.freeze
  NEW_EXTERNAL_COUPLING_DEMAND = 'external_coupling_energy_chemical_refineries_transformation_external_coupling_node_total_demand'.freeze

  OLD_PREFIX = 'external_coupling_industry_chemical_refineries_transformation_'.freeze
  NEW_PREFIX = 'external_coupling_energy_chemical_refineries_transformation_external_coupling_node_'.freeze

  OLD_OUTPUT_SHARE = ->(carrier) { "#{OLD_PREFIX}#{carrier}_output_share" }
  NEW_OUTPUT_SHARE = ->(carrier) { "#{NEW_PREFIX}#{carrier}_output_share" }
  NEW_INPUT_SHARE = ->(carrier) { "#{NEW_PREFIX}#{carrier}_input_share" }

  # Carriers that can be translated 1-to-1 for output shares. Refinery gas is treated differently later
  EXISTING_CARRIERS = %w[crude_oil diesel gasoline heavy_fuel_oil kerosene loss lpg].freeze
  # New output carriers that will be set to 0.0 share. Not_defined is treated differently later
  NEW_OUTPUT_CARRIERS = %w[ammonia greengas hydrogen methanol natural_gas].freeze

  # New input carriers that will be set to 0.0 share. Crude oil will be later set to 100
  NEW_INPUT_CARRIERS = %w[
    ammonia electricity greengas hydrogen methanol natural_gas not_defined
    steam_hot_water waste_mix wood_pellets
  ].freeze

  # Step 1: determine present_demand, determine future_demand, set future_demand
  # Step 2: assign input shares to new external coupling input shares
  # Step 3: assign output shares to new external coupling output shares
  def up
    @defaults = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    migrate_scenarios do |scenario|
      next unless scenario.user_values.key?(OLD_EXTERNAL_COUPLING_DEMAND)
      next unless Atlas::Dataset.exists?(scenario.area_code)

      assign_demand(scenario)
      assign_input_shares(scenario)
      assign_output_shares(scenario)
    end
  end

  private

  def assign_demand(scenario)
    present_demand = @defaults[scenario.area_code.to_s]['industry_refinery_transformation_crude_oil']

    scenario.user_values[NEW_EXTERNAL_COUPLING_DEMAND] = (
      (present_demand / 1000.0) *
      (scenario.user_values.delete(OLD_EXTERNAL_COUPLING_DEMAND) / 100.0)
    )
  end

  # Each new carrier gets an input share of 0.0. Crude oil gets an input of 100
  def assign_input_shares(scenario)
    NEW_INPUT_CARRIERS.each do |carrier|
      scenario.user_values[NEW_INPUT_SHARE.call(carrier)] = 0.0
    end
    scenario.user_values[NEW_INPUT_SHARE.call('crude_oil')] = 100.0
  end

  # Each new output carriers share is set to 0.0,
  # Each existing carriers share is copied over, with a special case for refinery
  # gas, which is allocated to not defined.
  def assign_output_shares(scenario)
    NEW_OUTPUT_CARRIERS.each do |carrier|
      scenario.user_values[NEW_OUTPUT_SHARE.call(carrier)] = 0.0
    end

    EXISTING_CARRIERS.each do |carrier|
      scenario.user_values[NEW_OUTPUT_SHARE.call(carrier)] =
        scenario.user_values.delete(OLD_OUTPUT_SHARE.call(carrier)) || 0.0
    end

    scenario.user_values[NEW_OUTPUT_SHARE.call('not_defined')] =
      scenario.user_values.delete(OLD_OUTPUT_SHARE.call('refinery_gas')) || 0.0
  end
end
