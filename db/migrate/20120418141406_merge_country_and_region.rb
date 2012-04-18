class MergeCountryAndRegion < ActiveRecord::Migration
  def up
    add_column :scenarios, :area_code, :string
    Scenario.reset_column_information
    Scenario.find_each do |s|
      area_code = s.region || s.country
      s.area_code = area_code
      s.save rescue puts "Error with scenario #{s.id}"
    end
  end

  def down
    remove_column :scenarios, :area_code
  end
end
