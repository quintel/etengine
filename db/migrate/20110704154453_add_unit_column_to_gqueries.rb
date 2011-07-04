class AddUnitColumnToGqueries < ActiveRecord::Migration
  def self.up
    add_column :gqueries, :unit, :string
  end

  def self.down
    remove_column :gqueries, :unit
  end
end
