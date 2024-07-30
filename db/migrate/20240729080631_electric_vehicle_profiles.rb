require 'etengine/scenario_migration'

class ElectricVehicleProfiles < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration
  include Scenario::Attachments
  include Qernel::Causality::AggregateCurve

  # NEW_PROFILE_MAPPING: A hash mapping new profile keys to their respective user value keys
  NEW_PROFILE_MAPPING = {
    electric_vehicle_profile_1_share: 'transport_car_using_electricity_public_charging_share',
    electric_vehicle_profile_2_share: 'transport_car_using_electricity_home_charging_share',
    electric_vehicle_profile_3_share: 'transport_car_using_electricity_fast_charging_share',
    electric_vehicle_profile_4_share: 'transport_car_using_electricity_work_charging_share',
    electric_vehicle_profile_5_share: 'transport_car_using_electricity_custom_profile_charging_share'
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
      # Target the specific test scenario
      next unless scenario.id == 2574213 # TODO REMOVE SCENRRIOS AFTER TESTING: 2574209, 2574210, 2574211, 2574212

      custom_profile = 0

      # Ensure the dataset for the scenario's area code exists
      unless Atlas::Dataset.exists?(scenario.area_code)
        next
      end

      dataset = Atlas::Dataset.find(scenario.area_code)

      # Check if any profile has an attachment
      has_attachment = EV_PROFILE_OLD.any? { |profile| scenario.attachment?(profile) }

      # Check if the profile shares are in the default ratio
      default_ratio = if scenario.user_values.empty?
        true
      else
        EV_PROFILE_SHARE_OLD.each_with_index.all? do |profile_share, index|
          scenario.user_values.fetch(profile_share, 0) == (index == 0 ? 100 : 0)
        end
      end

      if default_ratio
        if has_attachment
          # Rename keys and use attached custom curves to make the custom profile
          rename_keys(scenario, NEW_PROFILE_MAPPING)
          make_custom_profile(scenario, EV_PROFILE_SHARE_OLD, fetch_attached_curves(scenario, dataset))
        else
          # Just rename the keys if there are no attachments
          rename_keys(scenario, NEW_PROFILE_MAPPING)
        end
      else
        # Rename keys and create a custom profile based on current profiles
        rename_keys(scenario, NEW_PROFILE_MAPPING)
        make_custom_profile(scenario, EV_PROFILE_SHARE_OLD, fetch_attached_curves(scenario, dataset))
      end

      # Save the scenario
      scenario.save
      raise "Test scenario migration complete. Stopping further execution."
    end
  end

  private

  # Sets default share distribution and the custom_profile to be profile 5
  def setup_custom_profile(scenario, custom_profile)
    # Set all values to zero except for transport_car_using_electricity_custom_profile_charging_share
    NEW_PROFILE_MAPPING.values.each do |key|
      scenario.user_values[key] = (key == 'transport_car_using_electricity_custom_profile_charging_share') ? 1 : 0
    end

    # Set the custom profile to electric vehicle profile 5
    scenario.user_values['electric_vehicle_profile_5'] = custom_profile
  end

  # Creates a custom profile based on old shares and current profiles
  def make_custom_profile(scenario, old_share, current_profiles)
    mix = old_share.each_with_index.with_object({}) do |(key_share, index), hash|
      share = scenario.user_values[key_share] || 0
      profile = current_profiles[EV_PROFILE_OLD[index]]
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
      scenario.user_values[new_key] = scenario.user_values.delete(old_key)
    end
  end

  # Fetches attached curves for the profiles, or defaults if not attached
  def fetch_attached_curves(scenario, dataset)
    EV_PROFILE_OLD.inject({}) do |attachments_hash, profile|
      if scenario.attachment?(profile)
        attachments_hash[profile] = scenario.attachment(profile).file.download
      else
        attachments_hash[profile] = dataset.load_profile(profile.to_sym)
      end
      attachments_hash
    end
  end
end
