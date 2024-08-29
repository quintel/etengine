require 'etengine/scenario_migration'

class ElectricVehicleProfiles < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  # Mapping old electric vehicle charging share keys to new ones.
  NEW_SHARE_MAPPING = {
    'transport_car_using_electricity_hybrid_charging_share' => 'transport_car_using_electricity_public_charging_share',
    'transport_car_using_electricity_home_charging_share' => 'transport_car_using_electricity_home_charging_share',
    'transport_car_using_electricity_fast_charging_share' => 'transport_car_using_electricity_fast_charging_share',
    'transport_car_using_electricity_smart_charging_share' => 'transport_car_using_electricity_work_charging_share',
    'transport_car_using_electricity_regular_charging_share' => 'transport_car_using_electricity_custom_profile_charging_share'
  }.freeze

  # Old profile keys before migration. In order of correspondence to NEW_SHARE_MAPPING
  OLD_PROFILE_KEYS = %w[
    electric_vehicle_profile_1
    electric_vehicle_profile_2
    electric_vehicle_profile_3
    electric_vehicle_profile_4
    electric_vehicle_profile_5
  ].freeze

  # Executes the migration for all scenarios.
  def up
    migrate_scenarios do |scenario|
      # Only proceed if a dataset exists for the scenario's area code.
      next unless Atlas::Dataset.exists?(scenario.area_code)

      dataset = Atlas::Dataset.find(scenario.area_code)

      # Rename the user values based on the new key mapping.
      rename_keys(scenario)

      # If the scenario has any attached curves (user profiles).
      # Create and set up a custom profile based on the current setup.
      if OLD_PROFILE_KEYS.any? { |profile| scenario.attachment?("#{profile}_curve") }
        create_custom_profile(scenario, dataset)
      end
    end
  end

  private

  # Renames keys in the scenario's user values based on the provided mapping.
  def rename_keys(scenario)
    NEW_SHARE_MAPPING.each do |old_key, new_key|
      next unless scenario.user_values.key? (old_key)

      scenario.user_values[new_key] = scenario.user_values.delete(old_key)
    end
  end

  # Creates a custom profile based on the current profiles and their shares.
  def create_custom_profile(scenario, dataset)
    # Prepare a mix of profiles and their corresponding shares.
    mix = NEW_SHARE_MAPPING.values.each_with_index.filter_map do |key, index|
      next unless scenario.user_values[key]&.positive?

      profile = curve_for(scenario, dataset, OLD_PROFILE_KEYS[index])

      next unless profile

      [profile, scenario.user_values[key]]
    end

    # Exit if no profiles were found in the mix.
    return if mix.empty?

    # Use Merit to mix a new custom profile and set it on the scenario.
    set_custom_profile(
      scenario,
      ::Merit::CurveTools.add_curves(
        mix.map { |curve, share| Merit::Curve.new(curve) * share }
      )
    )
  end

  # Fetches attached curve for the profile or defaults to dataset profile if not attached.
  def curve_for(scenario, dataset, profile_key)
    if scenario.attachment?("#{profile_key}_curve")
      # If the user profile is attached, fetch the custom curve.
      CustomCurveSerializer.new(scenario.attachment("#{profile_key}_curve")).send(:curve)
    else
      # Otherwise, load the default profile from the dataset.
      dataset.load_profile(profile_key.to_sym)
    end
  end

  # Sets the custom profile with a 100% share and assigns it to profile 5.
  def set_custom_profile(scenario, custom_profile)
    # Set the custom profile share to 100% for the custom profile.
    NEW_SHARE_MAPPING.values.each { |key| scenario.user_values[key] = 0.0 }
    scenario.user_values['transport_car_using_electricity_custom_profile_charging_share'] = 100.0

    # Detach any existing electric vehicle profile curve attachments.
    OLD_PROFILE_KEYS.each do |profile_key|
      attachment = scenario.attachment("#{profile_key}_curve")
      CurveHandler::DetachService.call(attachment) if attachment
    end

    attach_custom_profile(scenario, custom_profile)
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
end
