require 'etengine/scenario_migration'

class RemoveHouseholdBehaviour < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # Retired household behaviour keys
  HOUSEHOLD_BEHAVIOUR_KEYS = %w[
    households_behavior_low_temperature_washing
    households_behavior_standby_killer_turn_off_appliances
    households_behavior_turn_off_the_light
    households_behavior_close_windows_turn_off_heating
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
