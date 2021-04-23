require 'etengine/scenario_migration'

class RemoveOldDatasetsNoSteelNoHighways < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  RENAME = {
    hengstdal: :nl
  }.freeze

  REMOVE_SUFFIX = %w[_no_highways _no_steel]

  def up
    # Rename datasets
    RENAME.each do |old_name, new_name|
      say_with_time "#{old_name} -> #{new_name}" do
        Scenario.where(area_code: old_name).update_all(area_code: new_name)
      end
    end

    # Change all no_highways- and no_steel-dataset scenarios in standard-dataset scenarios
    Scenario.all.each do |scenario|
      remove_any_suffix_from_area_code(scenario)
    end
  end

  private

  def remove_any_suffix_from_area_code(scenario)
    REMOVE_SUFFIX.each do |suffix|
      return if remove_suffix(scenario, suffix)
    end
  end

  def remove_suffix(scenario, suffix)
    return false unless scenario.area_code&.ends_with?(suffix)

    scenario.update(area_code: scenario.area_code.delete_suffix(suffix))
    true
  end
end
