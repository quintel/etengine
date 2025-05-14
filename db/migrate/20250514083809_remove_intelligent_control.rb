require 'etengine/scenario_migration'

class RemoveIntelligentControl < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # Retired household behaviour keys
  HOUSEHOLD_BEHAVIOUR_KEYS = %w[
    buildings_lighting_savings_from_motion_detection_light
    buildings_lighting_savings_from_daylight_control_light
  ].freeze

  def up
    migrate_scenarios do |scenario|

      # Check if one of household behaviour keys has been set, then remove them
      next unless HOUSEHOLD_BEHAVIOUR_KEYS.any? { |key| scenario.user_values.key?(key)}

      HOUSEHOLD_BEHAVIOUR_KEYS.each do |key|
        scenario.user_values.delete(key)
      end
    end
  end
end
