require 'etengine/scenario_migration'

class ElectricVehicleProfiles < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration
  include Scenario::Attachments

  # Mapping old electric vehicle charging share keys to new ones.
  NEW_SHARE_MAPPING = {
    transport_car_using_electricity_hybrid_charging_share: 'transport_car_using_electricity_public_charging_share',
    transport_car_using_electricity_home_charging_share: 'transport_car_using_electricity_home_charging_share',
    transport_car_using_electricity_fast_charging_share: 'transport_car_using_electricity_fast_charging_share',
    transport_car_using_electricity_smart_charging_share: 'transport_car_using_electricity_work_charging_share',
    transport_car_using_electricity_regular_charging_share: 'transport_car_using_electricity_custom_profile_charging_share'
  }.freeze

  # Old profile keys before migration.
  OLD_PROFILE_KEYS = %w[
    electric_vehicle_profile_1
    electric_vehicle_profile_2
    electric_vehicle_profile_3
    electric_vehicle_profile_4
    electric_vehicle_profile_5
  ].freeze

  # User profile keys that are attached to scenarios.
  USER_PROFILE_KEYS = %w[
    electric_vehicle_profile_1_curve
    electric_vehicle_profile_2_curve
    electric_vehicle_profile_3_curve
    electric_vehicle_profile_4_curve
    electric_vehicle_profile_5_curve
  ].freeze

  OLD_SHARE_KEYS = NEW_SHARE_MAPPING.keys.map(&:to_s)
  NEW_SHARE_KEYS = NEW_SHARE_MAPPING.values

  # Executes the migration for all scenarios.
  def up
    migrate_scenarios do |scenario|
      # Only proceed if a dataset exists for the scenario's area code.
      next unless Atlas::Dataset.exists?(scenario.area_code)

      dataset = Atlas::Dataset.find(scenario.area_code)

      # Rename the user values based on the new key mapping.
      rename_keys(scenario, NEW_SHARE_MAPPING)

      # Check if the scenario has any attached curves (user profiles).
      if USER_PROFILE_KEYS.any? { |profile| scenario.attachment?(profile) }
        # Fetch the current setup of attached curves or dataset profiles.
        current_setup = fetch_attached_curves(scenario, dataset)
        # Create and set up a custom profile based on the current setup.
        make_custom_profile(scenario, current_setup)
      end

      # Save the scenario and track the migration.
      scenario.save
      track_scenario_migration(scenario)
    end
  end

  private

  # Sets up a custom profile with a default share distribution and assigns it to profile 5.
  def setup_custom_profile(scenario, custom_profile)
    # Reset all new profile shares to zero.
    NEW_SHARE_KEYS.each { |key| scenario.user_values[key] = 0 }

    # Detach any existing electric vehicle profile curve attachments.
    USER_PROFILE_KEYS.each do |profile_key|
      attachment = scenario.attachment(profile_key)
      CurveHandler::DetachService.call(attachment) if attachment
    end

    # Set the custom profile share to 100% for 'electric_vehicle_profile_5_curve'.
    scenario.user_values['transport_car_using_electricity_custom_profile_charging_share'] = 100.0
    attach_custom_profile(scenario, custom_profile)
  end

  # Creates a custom profile based on the current profiles and their shares.
  def make_custom_profile(scenario, current_setup)
    mix = {}

    # Prepare a mix of profiles and their corresponding shares.
    NEW_SHARE_KEYS.each_with_index do |key, index|
      share = scenario.user_values[key] || 0.0
      profile_key = USER_PROFILE_KEYS[index]
      profile = current_setup[profile_key]

      mix[profile] = share if profile && share.positive?
    end

    # Exit if no profiles were found in the mix.
    return if mix.empty?

    # Aggregate the profiles and shares to create a custom profile.
    custom_profile = curve_aggregator(mix)
    return if custom_profile.nil?

    # Set up the custom profile in the scenario.
    setup_custom_profile(scenario, custom_profile)
  end

  # Renames keys in the scenario's user values based on the provided mapping.
  def rename_keys(scenario, new_mapping)
    new_mapping.each do |old_key, new_key|
      # Transfer values from old keys to new keys, defaulting to 0 if the old key is not present.
      scenario.user_values[new_key] = scenario.user_values.delete(old_key) || 0.0
    end
  end

  # Fetches attached curves for the profiles or defaults to dataset profiles if not attached.
  def fetch_attached_curves(scenario, dataset)
    attachments_hash = {}

    USER_PROFILE_KEYS.each_with_index do |user_profile_key, index|
      if scenario.attachment?(user_profile_key)
        # If the user profile is attached, fetch the custom curve.
        attachment = scenario.attachment(user_profile_key)
        custom_curve = CustomCurveSerializer.new(attachment).send(:curve)
        attachments_hash[user_profile_key] = custom_curve
      else
        # Otherwise, load the default profile from the dataset.
        attachments_hash[user_profile_key] = dataset.load_profile(OLD_PROFILE_KEYS[index].to_sym)
      end
    end

    attachments_hash
  end

  # Attaches the custom profile to the scenario as 'electric_vehicle_profile_5_curve'.
  def attach_custom_profile(scenario, custom_profile)
    config = CurveHandler::Config.find('electric_vehicle_profile_5')
    curve_data = custom_profile.to_a

    # Create a temporary file to store the curve data in CSV format.
    temp_file = Tempfile.new(['custom_profile', '.csv'])
    temp_file.write(curve_data.join("\n"))
    temp_file.rewind

    # Create a mock file object with necessary attributes.
    mock_file = ActionDispatch::Http::UploadedFile.new(
      tempfile: temp_file,
      filename: 'custom_profile.csv',
      type: 'text/csv'
    )

    # Use AttachService to attach the profile to the scenario.
    CurveHandler::AttachService.new(config, mock_file, scenario).call

    # Close and delete the temporary file.
    temp_file.close
    temp_file.unlink
  end

  # Aggregates the profiles and shares to create a custom profile.
  def curve_aggregator(mix)
    aggregated_curve = nil

    # Iterate over each curve and its associated share in the mix.
    mix.each do |curve, share|
      curve_values = curve.to_a
      scaled_curve = curve_values.map { |value| value * (share / 100.0) }

      aggregated_curve = if aggregated_curve.nil?
                           scaled_curve
                         else
                           aggregated_curve.each_with_index.map { |value, index| value + scaled_curve[index] }
                         end
    end

    Merit::Curve.new(aggregated_curve)
  end
end
