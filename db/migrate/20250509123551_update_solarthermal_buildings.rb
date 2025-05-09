require 'etengine/scenario_migration'

class UpdateSolarthermalBuildings < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios do |scenario|
      # Insert your code here which will migrate each scenario, and delete this
      # documentation comment.
      #

      if scenario.user_values.key?('buildings_space_heater_solar_thermal_share')
        scenario.user_values['buildings_space_heater_solar_thermal_share'] *= 0.13
      end
      #
      # If you need to reference data from Atlas, be sure to check that the
      # dataset used by the scenario still exists:
      #
      #   next unless Atlas::Dataset.exists?(scenario.area_code)
      #
      # Scenarios will be automatically saved if changes were made.
      #
      # ### Candidate scenarios
      #
      # By default, all `keep_updated` scenarios are migrated, along with any
      # other scenarios modified in the last month. You may supply a
      # custom cutoff date for migrating unprotected scenarios with the `since`
      # keyword argument.
      #
      # For example, to migrate scenarios up to three months old whose
      # `keep_updated` attribute is false:
      #
      #   migrate_scenarios(since: 3.months.ago) do |scenario|
      #     # ...
      #   end
      #
      # ### Errors
      #
      # An error will be raised if no scenarios were migrated, as it is often
      # unexpected for a migration to result in no changes. If you wish to
      # disable this behaviour, supply `raise_on_no_changes: false` to
      # `migrate_scenarios`. For example:
      #
      #   migrate_scenarios(raise_on_no_changes: false) do |scenario|
      #     # ...
      #   end
    end
  end
end
