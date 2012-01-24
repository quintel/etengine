class FixGqueries < ActiveRecord::Migration
  def self.up
    [144,652,653,655,656,657].each do |id|
      gquery = Gquery.find(id)
      gquery.query = gquery.query.gsub("of_imported_heat", "of_imported_steam_hot_water")
      gquery.query = gquery.query.gsub("of_steam_hotwater", "of_steam_hot_water")
      gquery.save
    end
    Gquery.find(679).destroy
    Gquery.find(514).destroy
    Gquery.find(515).destroy
  end

  def self.down
  end
end
