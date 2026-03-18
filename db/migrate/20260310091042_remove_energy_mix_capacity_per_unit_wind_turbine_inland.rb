require 'etengine/scenario_migration'

class RemoveEnergyMixCapacityPerUnitWindTurbineInland < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # Retired key
  KEY = 'energy_mix_capacity_per_unit_wind_turbine_inland'.freeze

  # As part of the retirement of the Energy mix we no longer need an input that only had effect on the Energy Mix infographic.
  # So the input with key 'energy_mix_capacity_per_unit_wind_turbine_inland', can be removed from existing scenarios.
  def up
    migrate_scenarios do |scenario|

      # Check if the key is set, then remove it
      scenario.user_values.delete(KEY) if scenario.user_values.key?(KEY)
    end
  end
end
