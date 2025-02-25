class RenameSomeOldDatasets < ActiveRecord::Migration[5.2]
  NAMES = {
    gemeente_groningen: :GM0014_groningen,
    "bd_etten-leur": :GM0777_etten_leur,
    om_haarlemmermeer: :GM0394_haarlemmermeer,
    antwerpen: :BEGM11002_antwerpen,
    RGUT01_u16: :RES24_u16,
    RGNB02_west_brabant: :RES28_west_brabant,
    RGNB03_hart_van_brabant: :RES09_hart_van_brabant,
    RGGL06_regio_cleantech: :RES26_cleantechregio,
    RGGL05_rivierenland: :RES25_rivierenland_fruitdelta,
    RGGL04_noord_veluwe: :RES18_noord_veluwe,
    RGGL03_food_valley: :RES05_foodvalley,
    RGGL02_regio_arnhem_nijmegen: :RES23_arnhem_nijmegen,
    RGGL01_achterhoek: :RES01_achterhoek
  }.freeze

  def up
    NAMES.each do |old_name, new_name|
      say_with_time "#{old_name} -> #{new_name}" do
        Scenario.where(area_code: old_name).update_all(area_code: new_name)
      end
    end
  end

  def down
    # Nothing to do.
  end
end
