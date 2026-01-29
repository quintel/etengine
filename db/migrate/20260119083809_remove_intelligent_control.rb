require 'etengine/scenario_migration'

class RemoveIntelligentControl < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # Retired buildings intelligent light keys
  BUILDINGS_INTELLIGENT_LIGHT_KEYS = %w[
      buildings_lighting_savings_from_daylight_control_light
      buildings_lighting_savings_from_motion_detection_light
  ].freeze

  # Old and new keys for development of demand appliances and lighting
  OLD_DEMAND_INPUT_KEY = 'buildings_useful_demand_electricity'
  NEW_DEMAND_INPUT_KEYS = %w[
      buildings_useful_demand_appliances
      buildings_useful_demand_lighting
  ].freeze

  # Start year useful demand edge values for daylight and motion control
  DEMAND_AFTER_DAYLIGHT_SHARE_START_YEAR = 0.947
  DEMAND_AFTER_MOTION_SHARE_START_YEAR = 0.961

  # Maximum values for intelligent light effects per year
  DAYLIGHT_CONTROL_MAX_VALUE = 387.0
  MOTION_DETECTION_MAX_VALUE = 680.0

  def up
    migrate_scenarios do |scenario|
      old_demand_set = scenario.user_values.key?(OLD_DEMAND_INPUT_KEY)
      intel_light_set = BUILDINGS_INTELLIGENT_LIGHT_KEYS.any? { |key| scenario.user_values.key?(key) }
      
      # Skip if neither intelligent light nor old demand inputs are set
      next unless old_demand_set || intel_light_set

      # Handle the three different combinations for demand inputs
      if old_demand_set && !intel_light_set
        # Only demand was set: split into appliances and lighting with same value
        demand_value = scenario.user_values[OLD_DEMAND_INPUT_KEY]
        scenario.user_values['buildings_useful_demand_appliances'] = demand_value
        scenario.user_values['buildings_useful_demand_lighting'] = demand_value
      elsif old_demand_set && intel_light_set
        # Both demand and intelligent light were set: combine effects for lighting
        demand_value = scenario.user_values[OLD_DEMAND_INPUT_KEY]
        combined_effect = demand_value + combined_intelligent_light_effect_per_year(scenario)
        scenario.user_values['buildings_useful_demand_appliances'] = demand_value
        scenario.user_values['buildings_useful_demand_lighting'] = combined_effect.clamp(-5.0, 5.0)
      elsif !old_demand_set && intel_light_set
        # Only intelligent light was set: use intelligent light effect for lighting
        intel_light_effect = combined_intelligent_light_effect_per_year(scenario)
        scenario.user_values['buildings_useful_demand_lighting'] = intel_light_effect.clamp(-5.0, 5.0)
      end

      # Remove old inputs from the scenario
      scenario.user_values.delete(OLD_DEMAND_INPUT_KEY)
      BUILDINGS_INTELLIGENT_LIGHT_KEYS.each { |key| scenario.user_values.delete(key) }
    end
  end

  private

  def combined_intelligent_light_effect_per_year(scenario)
    # Calculate daylight control effect (1.0 if not set = no effect)
    daylight_value = scenario.user_values['buildings_lighting_savings_from_daylight_control_light']
    useful_demand_effect_daylight = if daylight_value
      effect_daylight_control_end_year = daylight_value / DAYLIGHT_CONTROL_MAX_VALUE
      demand_after_daylight_share_end_year = 1.0 - effect_daylight_control_end_year
      demand_after_daylight_share_end_year / DEMAND_AFTER_DAYLIGHT_SHARE_START_YEAR
    else
      1.0
    end

    # Calculate motion detection effect (1.0 if not set = no effect)
    motion_value = scenario.user_values['buildings_lighting_savings_from_motion_detection_light']
    useful_demand_effect_motion = if motion_value
      effect_motion_detection_end_year = motion_value / MOTION_DETECTION_MAX_VALUE
      demand_after_motion_share_end_year = 1.0 - effect_motion_detection_end_year
      demand_after_motion_share_end_year / DEMAND_AFTER_MOTION_SHARE_START_YEAR
    else
      1.0
    end

    # Determine combined effect (multiply only the effects that were set, 1.0 = no effect)
    combined_intelligent_light_effect = useful_demand_effect_daylight * useful_demand_effect_motion

    # Convert combined effect to % per year
    years = scenario.end_year - scenario.start_year
    (combined_intelligent_light_effect ** (1.0 / years) - 1.0) * 100.0
  end
end
