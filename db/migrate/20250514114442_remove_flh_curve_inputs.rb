require 'etengine/scenario_migration'

class RemoveFlhCurveInputs < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # Retired household behaviour keys
  HOUSEHOLD_BEHAVIOUR_KEYS = %w[
  flh_of_geothermal_heat
  flh_of_hydro_river
  flh_of_solar_thermal
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