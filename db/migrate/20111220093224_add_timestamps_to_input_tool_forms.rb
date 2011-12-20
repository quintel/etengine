class AddTimestampsToInputToolForms < ActiveRecord::Migration
  def self.up
    add_column :input_tool_forms, :created_at, :datetime
    add_column :input_tool_forms, :updated_at, :datetime
  end

  def self.down
  end
end
