require 'etengine/scenario_migration'

# Defines a migration class for updating electric vehicle charging profiles
class ElectricVehicleProfiles < ActiveRecord::Migration[7.0]
  # Includes necessary modules for migration, scenario attachments, and curve aggregation
  include ETEngine::ScenarioMigration
  include Scenario::Attachments
  include Qernel::Causality::AggregateCurve

  # Maps old profile keys to their new user value keys
  NEW_PROFILE_MAPPING = {
    electric_vehicle_profile_1_share: 'transport_car_using_electricity_public_charging_share',
    electric_vehicle_profile_2_share: 'transport_car_using_electricity_home_charging_share',
    electric_vehicle_profile_3_share: 'transport_car_using_electricity_fast_charging_share',
    electric_vehicle_profile_4_share: 'transport_car_using_electricity_work_charging_share',
    electric_vehicle_profile_5_share: 'transport_car_using_electricity_custom_profile_charging_share'
  }.freeze

  # Lists old profile keys
  OLD_PROFILE_KEYS = %w[
    electric_vehicle_profile_1
    electric_vehicle_profile_2
    electric_vehicle_profile_3
    electric_vehicle_profile_4
    electric_vehicle_profile_5
  ].freeze

  # Lists old profile share keys
  OLD_PROFILE_SHARE_KEYS = %w[
    electric_vehicle_profile_1_share
    electric_vehicle_profile_2_share
    electric_vehicle_profile_3_share
    electric_vehicle_profile_4_share
    electric_vehicle_profile_5_share
  ].freeze

  # Defines the migration logic to be executed when applying the migration
  def up
    migrate_scenarios do |scenario|
      # Process only a specific test scenario (remove this check after testing)
      next unless scenario.id == 2574220 # TODO: Remove this check after testing

      # Check if the dataset for the scenario's area code exists
      next unless Atlas::Dataset.exists?(scenario.area_code)

      dataset = Atlas::Dataset.find(scenario.area_code)

      rename_keys(scenario, NEW_PROFILE_MAPPING) # Rename keys based on new mapping

      # If any old profile has an attachment, process the scenario accordingly
      if OLD_PROFILE_KEYS.any? { |profile| scenario.attachment?(profile) }
        make_custom_profile(scenario, fetch_attached_curves(scenario, dataset)) # Create and set up a custom profile
      end

      # Save the scenario after processing
      scenario.save
      raise "Test scenario migration complete. Stopping further execution." # TODO: Remove after testing
    end
  end

  private

  # Sets up a custom profile with a default share distribution and assigns it as profile 5
  def setup_custom_profile(scenario, custom_profile)
    # Set all new profile shares to zero
    NEW_PROFILE_MAPPING.values.each do |key|
      scenario.user_values[key] = 0
    end

    # Set the custom profile share to 100%
    scenario.user_values['transport_car_using_electricity_custom_profile_charging_share'] = 100.0

    # Assign the custom profile to the key for electric vehicle profile 5
    scenario.user_values['electric_vehicle_profile_5'] = custom_profile
  end

  # Creates a custom profile based on the current profiles and their shares
  def make_custom_profile(scenario, current_profiles)
    # Build a mix hash with profiles and their corresponding shares
    mix = NEW_PROFILE_MAPPING.values.each_with_index.with_object({}) do |(key_share, index), hash|
      share = scenario.user_values[key_share] || 0.0
      profile = current_profiles[OLD_PROFILE_KEYS[index]]
      hash[profile] = share
    end

    # Aggregate the profiles and shares to create a custom profile
    custom_profile = Qernel::Causality::AggregateCurve.build(mix)

    # Set up the custom profile in the scenario
    setup_custom_profile(scenario, custom_profile)
  end

  # Renames keys in the scenario's user values based on the provided mapping
  def rename_keys(scenario, new_mapping)
    new_mapping.each do |old_key, new_key|
      # Transfer values from old keys to new keys, defaulting to 0 if the old key is not present
      scenario.user_values[new_key] = scenario.user_values.delete(old_key) || 0.0
    end
  end

  # Fetches attached curves for the profiles or defaults to dataset profiles if not attached
  def fetch_attached_curves(scenario, dataset)
    OLD_PROFILE_KEYS.each_with_object({}) do |profile, attachments_hash|
      attachments_hash[profile] = if scenario.attachment?(profile)
                                    # Download the attached file if present
                                    scenario.attachment(profile).file.download
                                  else
                                    # Load the default profile from the dataset if no attachment is found
                                    dataset.load_profile(profile.to_sym)
                                  end
    end
  end
end
