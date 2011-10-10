class RemoveLegacyTables < ActiveRecord::Migration
  def self.up
    drop_table :press_releases
    drop_table :constraints
    drop_table :expert_predictions
    drop_table :general_user_notifications
    drop_table :output_elements
    drop_table :output_element_types
    drop_table :output_element_series
    drop_table :partners
    drop_table :policy_goals_root_nodes
    drop_table :sidebar_items
    drop_table :tabs
    drop_table :slides
    drop_table :translations
    drop_table :view_nodes
  end

  def self.down
  end
end
