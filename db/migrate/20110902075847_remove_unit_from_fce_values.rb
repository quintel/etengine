class RemoveUnitFromFceValues < ActiveRecord::Migration
  def self.up
    remove_column :fce_values, :unit
  end

  def self.down
    add_column :fce_values, :unit, :string, :default => "kg"
  end
end
