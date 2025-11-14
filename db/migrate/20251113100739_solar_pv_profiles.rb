class SolarPvProfiles < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  OLD_CURVE_KEY = 'weather/solar_pv_profile_1_curve'
  NEW_CURVE_KEYS = [
    'weather/solar_pv_on_roof_households_curve',
    'weather/solar_pv_on_roof_buildings_curve',
    'weather/solar_pv_on_land_curve'
  ]

  OLD_INPUT_KEY = 'flh_of_solar_pv_solar_radiation'
  NEW_INPUT_KEYS = %w[
    households_solar_pv_solar_radiation buildings_solar_pv_solar_radiation
    energy_power_solar_pv_solar_radiation energy_power_solar_pv_offshore
  ]


  def up
    @defaults = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    migrate_scenarios do |scenario|
      next unless Atlas::Dataset.exists?(scenario.area_code)

      copy_user_curves(scenario)
      user_curves_inputs(scenario)
      flh_inputs(scenario)
    end
  end

  # If a curve was uploaded, copy it over under the new keys
  def copy_user_curves(scenario)
    return unless scenario.attached_curve?(OLD_CURVE_KEY)

    old_curve = scenario.attached_curve(OLD_CURVE_KEY)
    new_attrs = old_curve.attributes.except("curve", "key", "id")
    new_attrs["curve"] = old_curve.curve.to_a

    NEW_CURVE_KEYS.each do |new_key|
      scenario.user_curves.build(new_attrs.merge(key: new_key))
    end

    old_curve.destroy! if scenario.save!
  end

  def user_curves_inputs(scenario)
    return unless scenario.user_values.key?("#{OLD_INPUT_KEY}_user_curve")

    NEW_INPUT_KEYS.each do |new_key|
      scenario.user_values["flh_of_#{new_key}_user_curve"] = scenario.user_values["#{OLD_INPUT_KEY}_user_curve"]
    end

    scenario.user_values.delete("#{OLD_INPUT_KEY}_user_curve")
  end

  def flh_inputs(scenario)
    return unless scenario.user_values.key?(OLD_INPUT_KEY)
    return if scenario.user_values[OLD_INPUT_KEY].nil?

    NEW_INPUT_KEYS.each do |new_key|
      input_min = @defaults[scenario.area_code][new_key] * 0.8
      input_max = @defaults[scenario.area_code][new_key] * 1.2

      scenario.user_values["flh_of_#{new_key}"] = if scenario.user_values[OLD_INPUT_KEY] > input_max
        input_max
      elsif scenario.user_values[OLD_INPUT_KEY] < input_min
        input_min
      else
        scenario.user_values[OLD_INPUT_KEY]
      end
    end

    scenario.user_values.delete(OLD_INPUT_KEY)
  end
end
