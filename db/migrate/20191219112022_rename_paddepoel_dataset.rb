class RenamePaddepoelDataset < ActiveRecord::Migration[5.2]
  NAMES = {
    paddepoel_noord: :BU00141002_paddepoel_noord
  }.freeze

  def up
    NAMES.each do |old_name, new_name|
      say_with_time "#{old_name} -> #{new_name}" do
        Scenario.where(area_code: old_name).update_all(area_code: new_name)
      end
    end
  end

  def down
    # Nothing to do.
  end
end