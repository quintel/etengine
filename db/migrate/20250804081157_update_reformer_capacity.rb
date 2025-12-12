require 'etengine/scenario_migration'

class UpdateReformerCapacity < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  KEYS = [
    'capacity_of_energy_hydrogen_lohc_reformer',
    'capacity_of_energy_hydrogen_liquid_hydrogen_regasifier'
  ].freeze

  SCALE_FACTOR = 4690.0 / 7884.0

  # The full load hours of LOHC reformers and LH2 regasifiers have been updated from 4690 to 7884.
  # Capacity is corrected to keep hydrogen output the same.
  def up
    migrate_scenarios do |scenario|
      KEYS.each do |key|
        scenario.user_values[key] *= SCALE_FACTOR if scenario.user_values.key?(key)
      end
    end
  end
end
