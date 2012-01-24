class RenameLceValuesIntoFceValues < ActiveRecord::Migration
  def self.up
    rename_table :lce_values, :fce_values
  end

  def self.down
    rename_table :fce_values, :lce_values
  end
end