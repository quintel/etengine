class DropScenarioTypeColumn < ActiveRecord::Migration
  def up
    remove_column :scenarios, :type
  end

  def down
    add_column :scenarios, :type, :string
    add_index :scenarios, :type
  end
end
