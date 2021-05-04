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
    REMOVE_SUFFIX.each do |suffix|
      say_with_time "remove #{suffix.inspect} suffix" do
        Scenario.where('area_code LIKE ?', "%#{suffix}%").find_each do |scenario|
          scenario.area_code = scenario.area_code.delete_suffix(suffix)
          scenario.save(validate: false, touch: false)
        end
      end
    end
  end
end
