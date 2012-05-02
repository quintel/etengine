class DropOldCountryAndRegionColumns < ActiveRecord::Migration
  def up
    remove_column :scenarios, :region
    remove_column :scenarios, :country
  end

  def down
    add_column :scenarios, :region, :string
    add_column :scenarios, :country, :string
  end
end
