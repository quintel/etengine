class RenameInputElementColumns < ActiveRecord::Migration
  def self.up
    rename_column :inputs, :input_element_type, :input_type
  end

  def self.down
    rename_column :inputs, :input_type, :input_element_type
  end
end