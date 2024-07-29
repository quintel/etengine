require 'etengine/scenario_migration'

class ElectricVehicleProfiles < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration
  include Scenario::Attachments

  # NEW_PROFILE_MAPPING: A hash mapping new profile keys to their respective user value keys
  NEW_PROFILE_MAPPING = {
    public_charging: 'transport_car_using_electricity_public_charging_share',
    home_charging: 'transport_car_using_electricity_home_charging_share',
    fast_charging: 'transport_car_using_electricity_fast_charging_share',
    work_charging: 'transport_car_using_electricity_work_charging_share',
    custom_profile: 'transport_car_using_electricity_custom_profile_charging_share'
  }.freeze

  # EV_PROFILE_SHARE_OLD: An array of old profile share keys
  EV_PROFILE_SHARE_OLD = %w[
    electric_vehicle_profile_1_share
    electric_vehicle_profile_2_share
    electric_vehicle_profile_3_share
    electric_vehicle_profile_4_share
    electric_vehicle_profile_5_share
  ].freeze

  # EV_PROFILE_OLD: An array of old profile keys
  EV_PROFILE_OLD = %w[
    electric_vehicle_profile_1
    electric_vehicle_profile_2
    electric_vehicle_profile_3
    electric_vehicle_profile_4
    electric_vehicle_profile_5
  ].freeze

  def up
    migrate_scenarios do |scenario|
      custom_profile = 0
      next unless Atlas::Dataset.exists?(scenario.area_code)

      dataset = Atlas::Dataset.find(scenario.area_code).dataset
      default_profiles = fetch_curves(dataset) # Fetch default profiles from the dataset

      has_attachment = EV_PROFILE_OLD.any? { |profile| scenario.attachment?(profile) } # Check if any profile has an attachment
      default_ratio = EV_PROFILE_SHARE_OLD.each_with_index.all? do |profile, index|
        scenario.user_values[profile] == (index == 0 ? 100 : 0) # Check if the values are in the default ratio
      end

      if default_ratio
        if has_attachment # Use attached custom curves to make the custom profile
          rename_keys(scenario, NEW_PROFILE_MAPPING)
          make_custom_profile(scenario, EV_PROFILE_SHARE_OLD, fetch_attached_curves(scenario), custom_profile)
        else
          rename_keys(scenario, NEW_PROFILE_MAPPING) # Just rename the keys if there are no attachments
        end
      else
        if has_attachment # Use attached custom curves to make the custom profile
          rename_keys(scenario, NEW_PROFILE_MAPPING)
          make_custom_profile(scenario, EV_PROFILE_SHARE_OLD, fetch_attached_curves(scenario), custom_profile)
        else
          rename_keys(scenario, NEW_PROFILE_MAPPING) # Use default profiles to make the custom profile with the set user values
          make_custom_profile(scenario, EV_PROFILE_SHARE_OLD, default_profiles, custom_profile)
        end
      end

      scenario.save
    end
  end

  private

  # Sets default share distribution and the custom_profile to be profile 5
  def setup_custom_profile(scenario, custom_profile)
    # Set all values to zero except for electric_vehicle_profile_5_share
    NEW_PROFILE_MAPPING.values.each do |key|
      scenario.user_values[key] = (key == 'transport_car_using_electricity_custom_profile_charging_share') ? 1 : 0
    end

    # Set the custom profile to ev profile 5
    scenario.user_values['electric_vehicle_profile_5'] = custom_profile
  end

  # Fetches a hash of the loaded profiles with profile names as the key and each value is the loaded profile
  def fetch_curves(dataset)
    EV_PROFILE_OLD.inject({}) do |loaded_profiles, profile|
      loaded_profiles[profile] = dataset.load_profile(profile.to_sym)
      loaded_profiles
    end
  end

  # Creates a custom profile based on old shares and current profiles
  def make_custom_profile(scenario, old_share, current_profiles, custom_profile)
    old_share.each_with_index do |key_share, index|
      custom_profile += (scenario.user_values[key_share] || 0) * (current_profiles[EV_PROFILE_OLD[index]] || 0)
    end
    setup_custom_profile(scenario, custom_profile)
  end

  # Renames keys in the scenario's user values based on the new mapping
  def rename_keys(scenario, new_mapping)
    new_mapping.each do |old_key, new_key|
      scenario.user_values[new_key] = scenario.user_values.delete(old_key)
    end
  end

  # Fetches attached curves for the profiles
  def fetch_attached_curves(scenario)
    EV_PROFILE_OLD.inject({}) do |attachments_hash, profile|
      if scenario.attachment?(profile)
        attachments_hash[profile] = scenario.attachment(profile).file.download
      end
      attachments_hash
    end
  end
end
