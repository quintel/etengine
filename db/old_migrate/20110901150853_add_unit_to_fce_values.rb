class AddUnitToFceValues < ActiveRecord::Migration
  def self.up
    add_column :fce_values, :unit, :string, :default => "kg"
  end

  def self.down
    remove_column :fce_values, :unit
  end
end