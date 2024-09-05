require 'etengine/scenario_migration'
require 'csv'

class ElectricVehicleProfiles < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  Transformation = Struct.new(:old_key, :new_key, :profile_name)

  TRANSFORMATION = [
    Transformation.new(
      old_key='transport_car_using_electricity_hybrid_charging_share',
      new_key='transport_car_using_electricity_public_charging_share',
      profile_name='electric_vehicle_profile_1_curve'
    ),
    Transformation.new(
      old_key='transport_car_using_electricity_home_charging_share',
      new_key='transport_car_using_electricity_home_charging_share',
      profile_name='electric_vehicle_profile_2_curve'
    ),
    Transformation.new(
      old_key='transport_car_using_electricity_fast_charging_share',
      new_key='transport_car_using_electricity_fast_charging_share',
      profile_name='electric_vehicle_profile_3_curve'
    ),
    Transformation.new(
      old_key='transport_car_using_electricity_smart_charging_share',
      new_key='transport_car_using_electricity_work_charging_share',
      profile_name='electric_vehicle_profile_4_curve'
    ),
    Transformation.new(
      old_key='transport_car_using_electricity_regular_charging_share',
      new_key='transport_car_using_electricity_custom_profile_charging_share',
      profile_name='electric_vehicle_profile_5_curve'
    )
  ].freeze


  # Executes the migration for all scenarios.
  def up
    @default_profiles = ElectricVehicleProfiles.new

    migrate_scenarios do |scenario|
      create_custom_profile(scenario) if rename_keys(scenario)
    end
  end

  private

  # Renames keys in the scenario's user values based on the provided mapping.
  # When the inputs were untouched, set the last input to 100%.
  # Returns true when we should mix a custom profile.
  def rename_keys(scenario)
    if any_old_keys_set?(scenario) || any_uploaded_curves?(scenario)
      TRANSFORMATION.each do |transformation|
        next unless scenario.user_values.key? (transformation.old_key)

        scenario.user_values[transformation.new_key] = scenario.user_values.delete(transformation.old_key)
      end

      true
    else
      set_custom_to_100_for(scenario)

      false
    end
  end

  def any_uploaded_curves?(scenario)
    TRANSFORMATION.map(&:profile_name).any? { |key| scenario.attachment?(key) }
  end

  def any_old_keys_set?(scenario)
    TRANSFORMATION.map(&:old_key).any? { |key| scenario.user_values.key?(key) }
  end

  def set_custom_to_100_for(scenario)
    TRANSFORMATION.map(&:new_key).each do |new_key|
      scenario.user_values[new_key] = 0.0
    end

    scenario.user_values[TRANSFORMATION.last.new_key] = 100.0
  end

  # Creates a custom profile based on the current profiles and their shares.
  # Use Merit to mix a new custom profile and set it on the scenario.
  def create_custom_profile(scenario)
    curves = weighted_curves_for(scenario)
    set_custom_profile(
      scenario,
      curves.one? ? curves.first : ::Merit::CurveTools.add_curves(curves)
    )
  end

  # Returns an array of profiles times their corresponding shares.
  # If no curve was attached, uses the default profile.
  # Returns array of Merit::Curve
  def weighted_curves_for(scenario)
    TRANSFORMATION.filter_map do |transformation|
      next unless scenario.user_values[transformation.new_key]&.positive?

      (
        attached_curve_for(scenario, transformation.profile_name) ||
        @default_profiles.public_send(transformation.profile_name)
      ) *
        scenario.user_values[transformation.new_key]
    end
  end

  # Fetches attached curve for the profile. Returns nil if no profile was attached.
  def attached_curve_for(scenario, profile_key)
    return unless scenario.attachment?(profile_key)

    Merit::Curve.new(
      CustomCurveSerializer.new(scenario.attachment(profile_key)).send(:curve)
    )
  end

  # Sets the custom profile with a 100% share and assigns it to profile 5.
  def set_custom_profile(scenario, custom_profile)
    set_custom_to_100_for(scenario)

    # Detach any existing electric vehicle profile curve attachments.
    TRANSFORMATION.each do |transformation|
      next unless scenario.attachment?(transformation.profile_name)

      CurveHandler::DetachService.call(scenario.attachment(transformation.profile_name))
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

  class ElectricVehicleProfiles

    def parse_csv(number)
      File.open("#{__dir__}/#{File.basename(__FILE__, '.rb')}/electric_vehicle_profile_#{number}.csv") do |file|
        CSV.parse(file, converters: [:float])
      end.flatten
    end

    def electric_vehicle_profile_1_curve
      @electric_vehicle_profile_1_curve ||= ::Merit::Curve.new(parse_csv(1))
    end

    def electric_vehicle_profile_2_curve
      @electric_vehicle_profile_2_curve ||= ::Merit::Curve.new(parse_csv(2))
    end

    def electric_vehicle_profile_3_curve
      @electric_vehicle_profile_3_curve ||= ::Merit::Curve.new(parse_csv(3))
    end

    def electric_vehicle_profile_4_curve
      @electric_vehicle_profile_4_curve ||= ::Merit::Curve.new(parse_csv(4))
    end

    def electric_vehicle_profile_5_curve
      @electric_vehicle_profile_5_curve ||= ::Merit::Curve.new(parse_csv(5))
    end
  end
end
