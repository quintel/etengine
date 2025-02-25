class RemoveOldScenarioAttributes < ActiveRecord::Migration[7.0]
  def change
    remove_column :scenarios, :author, :string
    remove_column :scenarios, :old_title, :string
    remove_column :scenarios, :old_description, :text
    remove_column :scenarios, :api_read_only, :boolean, default: false
    remove_column :scenarios, :in_start_menu, :boolean
    remove_column :scenarios, :use_fce, :boolean
    remove_column :scenarios, :present_updated_at, :datetime, precision: nil
  end
end
