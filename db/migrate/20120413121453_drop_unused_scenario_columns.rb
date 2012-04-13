class DropUnusedScenarioColumns < ActiveRecord::Migration
  def self.up
    remove_column :scenarios, :user_updates
    remove_column :scenarios, :complexity
    remove_column :scenarios, :scenario_type
  end

  def self.down
    add_column :scenarios, :user_updates, :text
    add_column :scenarios, :complexity, :integer
    add_column :scenarios, :scenario_type, :string
  end
end
