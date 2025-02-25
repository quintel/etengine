require 'etengine/scenario_migration'

class RenameAmersfoort < ActiveRecord::Migration[5.2]
  RENAME = {
    GM0307_amersfoort: :GM0307_amersfoort_2016
  }.freeze

  def up
    RENAME.each do |old_name, new_name|
      say_with_time "#{old_name} -> #{new_name}" do
        Scenario.where(area_code: old_name).update_all(area_code: new_name)
      end
    end
  end

  def down
    RENAME.each do |old_name, new_name|
      say_with_time "#{new_name} -> #{old_name}" do
        Scenario.where(area_code: new_name).update_all(area_code: old_name)
      end
    end
  end
end
