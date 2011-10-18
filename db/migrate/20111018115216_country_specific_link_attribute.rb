class CountrySpecificLinkAttribute < ActiveRecord::Migration
  def self.up
    add_column :links, :country_specific, :integer
  end

  def self.down
    remove_column :links, :country_specific
  end
end
