class ChangeInputElementsToInputs < ActiveRecord::Migration
  def self.up
    rename_table :input_elements, :inputs
  end

  def self.down
    rename_table :inputs, :input_elements
  end
end