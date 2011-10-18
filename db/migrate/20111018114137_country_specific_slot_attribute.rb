class CountrySpecificSlotAttribute < ActiveRecord::Migration
  def self.up
    add_column :slots, :country_specific, :integer
  end

  def self.down
    remove_column :slots, :country_specific
  end
end
