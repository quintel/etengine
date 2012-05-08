class RenameAndRemoveInsulationBuildingAttributes < ActiveRecord::Migration
  def self.up
    remove_column :areas, :buildings_heating_share_offices
    remove_column :areas, :buildings_heating_share_other
    remove_column :areas, :buildings_heating_share_schools
    remove_column :areas, :insulation_level_offices
    rename_column :areas,
      :insulation_level_schools,
      :insulation_level_buildings
  end

  def self.down
    add_column :areas, :buildings_heating_share_offices
    add_column :areas, :buildings_heating_share_other
    add_column :areas, :buildings_heating_share_schools
    add_column :areas, :insulation_level_offices
    rename_column :areas,
      :insulation_level_buildings,
      :insulation_level_schools
  end
end
