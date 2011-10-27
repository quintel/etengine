class AddAreaInputValues < ActiveRecord::Migration
  def self.up
    add_column :areas, :input_values, :text
  end

  def self.down
    remove_column :areas, :input_values
  end
end