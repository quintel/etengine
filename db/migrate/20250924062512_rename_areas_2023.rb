require 'etengine/scenario_migration'

class RenameAreas2023 < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  AREA_CODE_MAPPING = {
      # === Province rename ===
      "PV21_friesland"              => "PV21_fryslan",

      # === RES → ES renames ===
      "RES08_groningen"             => "ES01_groningen",
      "RES06_regio_friesland"       => "ES02_friesland",
      "RES03_regio_drenthe"         => "ES03_drenthe",
      "RES27_twente"                => "ES04_twente",
      "RES29_west_overijssel"       => "ES05_west_overijssel",
      "RES04_flevoland"             => "ES06_flevoland",
      "RES01_achterhoek"            => "ES07_achterhoek",
      "RES23_arnhem_nijmegen"       => "ES08_arnhem_nijmegen",
      "RES05_foodvalley"            => "ES09_foodvalley",
      "RES18_noord_veluwe"          => "ES10_noord_veluwe",
      "RES25_rivierenland_fruitdelta" => "ES11_fruitdelta_rivierenland",
      "RES26_cleantechregio"        => "ES12_stedendriehoek",
      "RES22_amersfoort"            => "ES13_amersfoort",
      "RES24_u16"                   => "ES14_u16",
      "RES16_noord_holland_noord"   => "ES15_noord_holland_noord",
      "RES17_noord_holland_zuid"    => "ES16_noord_holland_zuid",
      "RES21_alblasserwaard"        => "ES17_alblasserwaard",
      "RES02_drechtsteden"          => "ES18_drechtsteden",
      "RES07_goeree_overflakkee"    => "ES19_goeree_overflakkee",
      "RES10_hoeksewaard"           => "ES20_hoeksche_waard",
      "RES11_holland_rijnland"      => "ES21_holland_rijnland",
      "RES14_midden_holland"        => "ES22_midden_holland",
      "RES13_rotterdam_denhaag"     => "ES23_rotterdam_den_haag",
      "RES30_zeeland"               => "ES24_zeeland",
      "RES09_hart_van_brabant"      => "ES25_hart_van_brabant",
      "RES12_metropoolregio_eindhoven"  => "ES26_metropoolregio_eindhoven",
      "RES20_noord_oost_brabant"        => "ES27_noordoost_brabant",
      "RES28_west_brabant"              => "ES28_west_brabant",
      "RES19_noord_en_midden_limburg"   => "ES29_noord_en_midden_limburg",
      "RES31_zuid_limburg"              => "ES30_zuid_limburg"
    }.freeze

  def up
    migrate_scenarios do |scenario|
      if AREA_CODE_MAPPING.key?(scenario.area_code)
        new_code = AREA_CODE_MAPPING[scenario.area_code]
        scenario.update!(area_code: new_code)
      end
    end
  end
end
