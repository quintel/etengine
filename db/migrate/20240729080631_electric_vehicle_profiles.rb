require 'etengine/scenario_migration'

# Defines a migration class for updating electric vehicle charging profiles
class ElectricVehicleProfiles < ActiveRecord::Migration[7.0]
  # Includes necessary modules for migration, scenario attachments, and curve aggregation
  include ETEngine::ScenarioMigration
  include Scenario::Attachments
  include Qernel::Causality::AggregateCurve

  # Maps old share keys to their new keys
  NEW_SHARE_MAPPING = {
    transport_car_using_electricity_hybrid_charging_share: 'transport_car_using_electricity_public_charging_share',
    transport_car_using_electricity_home_charging_share: 'transport_car_using_electricity_home_charging_share',
    transport_car_using_electricity_fast_charging_share: 'transport_car_using_electricity_fast_charging_share',
    transport_car_using_electricity_smart_charging_share: 'transport_car_using_electricity_work_charging_share',
    transport_car_using_electricity_regular_charging_share: 'transport_car_using_electricity_custom_profile_charging_share'
  }.freeze

  # Lists old profile keys
  OLD_PROFILE_KEYS = %w[
    electric_vehicle_profile_1
    electric_vehicle_profile_2
    electric_vehicle_profile_3
    electric_vehicle_profile_4
    electric_vehicle_profile_5
  ].freeze

  # User profile keys (attached curves)
  USER_PROFILE_KEYS = %w[
    electric_vehicle_profile_1_curve
    electric_vehicle_profile_2_curve
    electric_vehicle_profile_3_curve
    electric_vehicle_profile_4_curve
    electric_vehicle_profile_5_curve
  ].freeze

  OLD_SHARE_KEYS = NEW_SHARE_MAPPING.keys.map(&:to_s)
  NEW_SHARE_KEYS = NEW_SHARE_MAPPING.values

  # Defines the migration logic to be executed when applying the migration
  def up
    migrate_scenarios do |scenario|
      # Process only a specific test scenario (remove this check after testing) -- ALSO REMOVE ALL PUTS AND THE RAISE STATEMENT
      next unless scenario.id == 2574271 # TODO: Remove this check after testing

      puts("Starting migration for scenario #{scenario.id}")

      # Check if the dataset for the scenario's area code exists
      if Atlas::Dataset.exists?(scenario.area_code)
        dataset = Atlas::Dataset.find(scenario.area_code)
        puts("Dataset found for area code #{scenario.area_code}")

        rename_keys(scenario, NEW_SHARE_MAPPING) # Rename keys based on new mapping

        # If any old profile has an attachment, process the scenario accordingly
        if USER_PROFILE_KEYS.any? { |profile| scenario.attachment?(profile) }
          puts("Attached curves found for scenario #{scenario.id}")
          current_setup = fetch_attached_curves(scenario, dataset)
          make_custom_profile(scenario, current_setup) # Create and set up a custom profile
        else
          puts("No attached curves found for scenario #{scenario.id}")
        end

        # Save the scenario after processing
        scenario.save
        puts("Scenario #{scenario.id} saved successfully")
        raise "Test scenario migration complete. Stopping further execution." # TODO: Remove after testing
      else
        puts("No dataset found for area code #{scenario.area_code}")
      end
    end
  end

  private

  # Sets up a custom profile with a default share distribution and assigns it as profile 5
  def setup_custom_profile(scenario, custom_profile)
    puts("Setting up custom profile for scenario #{scenario.id}")

    # Set all new profile shares to zero
    NEW_SHARE_KEYS.each do |key|
      scenario.user_values[key] = 0
    end

    # Remove any existing electric vehicle profile curve attachments
    USER_PROFILE_KEYS.each do |profile_key|
      attachment = scenario.attachment(profile_key)

      if attachment
        CurveHandler::DetachService.call(attachment)
      else
        puts("No attachment found for key: #{profile_key}")
      end
    end

    # Set the custom profile share to 100%
    scenario.user_values['transport_car_using_electricity_custom_profile_charging_share'] = 100.0

    # Assign the custom profile to the key for electric vehicle profile 5
    attach_custom_profile(scenario, custom_profile)
    puts("Custom profile set to electric_vehicle_profile_5_curve for scenario #{scenario.id}")
  end

  # Creates a custom profile based on the current profiles and their shares
  def make_custom_profile(scenario, current_setup)
    puts("Creating custom profile for scenario #{scenario.id}")

    mix = {}     # Structure of mix: { key: { share: share, profile: profile } }

    NEW_SHARE_KEYS.each_with_index do |key, index|
      share = scenario.user_values[key] || 0.0
      profile_key = USER_PROFILE_KEYS[index]
      profile = current_setup[profile_key]

      mix[profile] = share if profile && share.positive?
    end

    # Aggregate the profiles and shares to create a custom profile
    custom_profile = Qernel::Causality::AggregateCurve.build(mix)           # THIS IS WHERE IT'S GOING WRONG CURRENTLY !!!!!!!!!!! - maybe because of the attachments

    puts("Custom profile created for scenario #{scenario.id}: #{custom_profile.inspect}")

    # Set up the custom profile in the scenario
    setup_custom_profile(scenario, custom_profile)
  end

  # Renames keys in the scenario's user values based on the provided mapping
  def rename_keys(scenario, new_mapping)
    puts("Renaming keys for scenario #{scenario.id}")

    new_mapping.each do |old_key, new_key|
      # Transfer values from old keys to new keys, defaulting to 0 if the old key is not present
      scenario.user_values[new_key] = scenario.user_values.delete(old_key) || 0.0
    end

    puts("Keys renamed for scenario #{scenario.id}")
  end

  # Fetches attached curves for the profiles or defaults to dataset profiles if not attached
  def fetch_attached_curves(scenario, dataset)
    puts("Fetching attached curves for scenario #{scenario.id}")

    attachments_hash = {}

    USER_PROFILE_KEYS.each_with_index do |user_profile_key, index|
      if scenario.attachment?(user_profile_key)
        attachment = scenario.attachment(user_profile_key)  # This is a ScenarioAttachment object, not a curve!
        custom_curve = CustomCurveSerializer.new(attachment).send(:curve) # Hopefully this is a curve
        attachments_hash[user_profile_key] = custom_curve
      else
        attachments_hash[user_profile_key] = dataset.load_profile(OLD_PROFILE_KEYS[index].to_sym)
      end
    end
    attachments_hash
  end

  def create_curve(mix)
    return zeroed_profile if mix.empty? || mix.values.sum.zero?

    Merit::CurveTools.add_curves(
      balanced_mix(mix)
        .map { |prof, share| prof * share if share.positive? }
        .compact
    )

  end

  def attach_custom_profile(scenario, custom_profile)
    puts("Attaching custom profile to electric_vehicle_profile_5_curve for scenario #{scenario.id}")

    # Find the configuration for the profile key.
    config = CurveHandler::Config.find('electric_vehicle_profile_5')

    # Convert the custom profile (Merit::Curve) into a format that AttachService can handle.
    curve_data = custom_profile.to_a # Converts the Merit::Curve to an array of values

    # Create a temporary file to store the curve data in CSV format
    temp_file = Tempfile.new(['custom_profile', '.csv'])
    temp_file.write(curve_data.join("\n")) # Write the array data as lines in the CSV
    temp_file.rewind

    # Create a mock file object with necessary attributes.
    mock_file = ActionDispatch::Http::UploadedFile.new(
      tempfile: temp_file,
      filename: 'custom_profile.csv',
      type: 'text/csv'
    )

    # Use AttachService to attach the profile to the scenario.
    attach_service = CurveHandler::AttachService.new(config, mock_file, scenario)

    if attach_service.call
      puts("Custom profile successfully attached to electric_vehicle_profile_5_curve.")
    else
      puts("Failed to attach custom profile: #{attach_service.errors.full_messages.join(', ')}")
    end

    # Close and delete the temporary file
    temp_file.close
    temp_file.unlink
  end

end
