class AddScenarioProtectedFlag < ActiveRecord::Migration
  def self.up
    add_column :scenarios, :protected, :boolean
    add_index :scenarios, :protected
  end

  def self.down
    remove_column :scenarios, :protected
  end
end
