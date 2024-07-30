require 'etengine/scenario_migration'

class ElectricVehicleProfiles < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration
  include Scenario::Attachments
  include Qernel::Causality::AggregateCurve

  # Mapping old profile keys to their new user value keys
  NEW_PROFILE_MAPPING = {
    electric_vehicle_profile_1_share: 'transport_car_using_electricity_public_charging_share',
    electric_vehicle_profile_2_share: 'transport_car_using_electricity_home_charging_share',
    electric_vehicle_profile_3_share: 'transport_car_using_electricity_fast_charging_share',
    electric_vehicle_profile_4_share: 'transport_car_using_electricity_work_charging_share',
    electric_vehicle_profile_5_share: 'transport_car_using_electricity_custom_profile_charging_share'
  }.freeze

  # Old profile keys
  OLD_PROFILE_KEYS = %w[
    electric_vehicle_profile_1
    electric_vehicle_profile_2
    electric_vehicle_profile_3
    electric_vehicle_profile_4
    electric_vehicle_profile_5
  ].freeze

  # Old profile share keys
  OLD_PROFILE_SHARE_KEYS = %w[
    electric_vehicle_profile_1_share
    electric_vehicle_profile_2_share
    electric_vehicle_profile_3_share
    electric_vehicle_profile_4_share
    electric_vehicle_profile_5_share
  ].freeze

  def up
    migrate_scenarios do |scenario|
      # Only target specific test scenarios (remove this check after testing)
      next unless scenario.id == 2574220 # TODO: Remove this check after testing

      # Ensure the dataset for the scenario's area code exists
      next unless Atlas::Dataset.exists?(scenario.area_code)

      dataset = Atlas::Dataset.find(scenario.area_code)

      # Check if any profile has an attachment
      if OLD_PROFILE_KEYS.any? { |profile| scenario.attachment?(profile) }
        rename_keys(scenario, NEW_PROFILE_MAPPING)
        make_custom_profile(scenario, fetch_attached_curves(scenario, dataset))
      else
        rename_keys(scenario, NEW_PROFILE_MAPPING)
      end

      # Save the scenario
      scenario.save
      raise "Test scenario migration complete. Stopping further execution." # TODO: Remove after testing
    end
  end

  private

  # Sets default share distribution and the custom profile to be profile 5
  def setup_custom_profile(scenario, custom_profile)
    # Set all profile shares to zero
    NEW_PROFILE_MAPPING.values.each do |key|
      scenario.user_values[key] = 0
    end

    # Set the custom profile share to 100
    scenario.user_values['transport_car_using_electricity_custom_profile_charging_share'] = 100

    # Assign the custom profile to electric vehicle profile 5
    scenario.user_values['electric_vehicle_profile_5'] = custom_profile
  end

  # Creates a custom profile based on current profiles
  def make_custom_profile(scenario, current_profiles)
    mix = NEW_PROFILE_MAPPING.values.each_with_index.with_object({}) do |(key_share, index), hash|
      share = scenario.user_values[key_share] || 0
      profile = current_profiles[OLD_PROFILE_KEYS[index]]
      hash[profile] = share
    end

    # Aggregate the mix to build the custom profile
    custom_profile = Qernel::Causality::AggregateCurve.build(mix)

    # Setup the custom profile in the scenario
    setup_custom_profile(scenario, custom_profile)
  end

  # Renames keys in the scenario's user values based on the new mapping
  def rename_keys(scenario, new_mapping)
    new_mapping.each do |old_key, new_key|
      scenario.user_values[new_key] = scenario.user_values.delete(old_key) || 0
    end
  end

  # Fetches attached curves for the profiles, or defaults if not attached
  def fetch_attached_curves(scenario, dataset)
    OLD_PROFILE_KEYS.each_with_object({}) do |profile, attachments_hash|
      attachments_hash[profile] = if scenario.attachment?(profile)
                                    scenario.attachment(profile).file.download
                                  else
                                    dataset.load_profile(profile.to_sym)
                                  end
    end
  end
end
