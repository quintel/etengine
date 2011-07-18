class AddHasFceToAreas < ActiveRecord::Migration
  def self.up
    add_column :areas, :has_fce, :boolean
  end

  def self.down
    remove_column :areas, :has_fce
  end
end