class AddHasIndustryAndHasOtherToAreas < ActiveRecord::Migration
  def self.up
    add_column :areas, :has_industry, :boolean
    add_column :areas, :has_other, :boolean
  end

  def self.down
    remove_column :areas, :has_other
    remove_column :areas, :has_industry
  end
end