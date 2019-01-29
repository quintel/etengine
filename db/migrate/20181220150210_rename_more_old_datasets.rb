class RenameMoreOldDatasets < ActiveRecord::Migration[5.1]
  RENAMED = {
    'amersfoort' => 'GM0307_amersfoort',
    'goes' => 'GM0664_goes',
    'noord-beveland' => 'GM1695_noord_beveland',
    'schouwen-duiveland' => 'GM1676_schouwen_duiveland',
    'selwerd' => 'BU00141000_selwerd',
    'stedendriehoek' => 'om_cleantech-regio',
    'u16' => 'RGUT01_u16',
    'ijmond-zuid-kennemerland' => 'RGNH01_ijmond_zuid_kennemerland',
    'zaanstreek-waterland' => 'RGNH02_zaanstreek_waterland',
    'gooi_en_vechtstreek' => 'RGNH03_gooi_en_vechtstreek',
    'amstelland-meerlanden' => 'RGNH04_amstelland_meerlanden',
    'kop_van_noord-holland' => 'RGNH05_kop_van_noord_holland',
    'regio_alkmaar' => 'RGNH06_regio_alkmaar',
    'west-friesland' => 'RGNH07_west_friesland',
    'drenthe' => 'PV22_drenthe',
    'groningen' => 'PV20_groningen',
    'zeeland' => 'PV29_zeeland',
    'utrecht_province' => 'PV26_utrecht',
    'vijfheerenlanden' => 'GM1961_vijfheerenlanden',
    'GM0394_haarlemmermeer' => 'CT01_haarlemmermeer',
    'PV27_noord-holland' => 'PV27_noord_holland',
    'GM0385_edam-volendam' => 'GM0385_edam_volendam',
    'GM0437_ouder-amstel' => 'GM0437_ouder_amstel',
    'GM1901_bodegraven-reeuwijk' => 'GM1901_bodegraven_reeuwijk',
    'BU00090003_sint-annen' => 'BU00090003_sint_annen',
    'BU00090005_achter-thesinge_en_bovenrijge' => 'BU00090005_achter_thesinge_en_bovenrijge',
    'BU00140000_binnenstad-noord' => 'BU00140000_binnenstad_noord',
    'BU00140001_binnenstad-zuid' => 'BU00140001_binnenstad_zuid',
    'BU00140002_binnenstad-oost' => 'BU00140002_binnenstad_oost',
    'BU00140003_binnenstad-west' => 'BU00140003_binnenstad_west',
    'BU00140005_hortusbuurt-ebbingekwartier' => 'BU00140005_hortusbuurt_ebbingekwartier',
    'BU00140606_de_wijert-zuid' => 'BU00140606_de_wijert_zuid',
    'BU00140801_hoogkerk-zuid' => 'BU00140801_hoogkerk_zuid',
    'BU00140900_vinkhuizen-noord' => 'BU00140900_vinkhuizen_noord',
    'BU00140901_vinkhuizen-zuid' => 'BU00140901_vinkhuizen_zuid',
    'BU00141002_paddepoel-noord' => 'BU00141002_paddepoel_noord',
    'BU00141001_paddepoel-zuid' => 'BU00141001_paddepoel_zuid',
    'BU00141202_lewenborg-west' => 'BU00141202_lewenborg_west',
    'BU00141201_lewenborg-zuid' => 'BU00141201_lewenborg_zuid',
    'BU00141200_lewenborg-noord' => 'BU00141200_lewenborg_noord',
    'BU00141101_beijum-oost' => 'BU00141101_beijum_oost',
    'BU00141100_beijum-west' => 'BU00141100_beijum_west',
    'BU00170106_verspreide_huizen_ten_westen_van_noord-willemskanaal' => 'BU00170106_verspreide_huizen_ten_westen_van_noord_willemskanaal',
    'bd_aalburg' => 'GM0738_aalburg',
    'bd_alphen-chaam' => 'GM0716_alphen_chaam',
    'bd_baarle-nassau' => 'GM0738_baarle_nassau',
    'bd_bergen-op-zoom' => 'GM0744_bergen_op_zoom',
    'bd_breda' => 'GM0748_breda',
    'bd_dongen' => 'GM0758_dongen',
    'bd_drimmelen' => 'GM0766_drimmelen',
    'bd_geertruidenberg' => 'GM0779_geertruidenberg',
    'bd_gilze-en-rijen' => 'GM0784_gilze_en_rijen',
    'bd_goirle' => 'GM0785_goirle',
    'bd_halderberge' => 'GM0797_halderberge',
    'bd_heusden' => 'GM0798_heusden',
    'bd_hilvarenbeek' => 'GM0809_hilvarenbeek',
    'bd_loon-op-zand' => 'GM0824_loon_op_zand',
    'bd_moerdijk' => 'GM0826_moerdijk',
    'bd_oisterwijk' => 'GM0840_oisterwijk',
    'bd_oosterhout' => 'GM0851_oosterhout',
    'bd_roosendaal' => 'GM0855_roosendaal',
    'bd_rucphen' => 'GM0867_rucphen',
    'bd_steenbergen' => 'GM0870_steenbergen',
    'bd_tholen' => 'GM0873_tholen',
    'bd_tilburg' => 'GM0874_tilburg',
    'bd_waalwijk' => 'GM0879_waalwijk',
    'bd_werkendam' => 'GM1655_werkendam',
    'bd_woensdrecht' => 'GM1674_woensdrecht',
    'bd_woudrichem' => 'GM1709_woudrichem',
    'bd_zundert' => 'GM1723_zundert',
    'bd_hart-van-brabant' => 'RGNB03_hart_van_brabant',
    'bd_west-brabant' => 'RGNB02_west_brabant',
    'bd_west-en-midden-brabant' => 'RGNB01_west_en_midden_brabant'
  }.freeze

  DELETED = %i[
    baarland
    de_biezen
    oostkapelle
    s_heer_hendrikskinderen
    veere
  ].freeze

  def up
    say_with_time 'Removing scenarios using old datasets' do
      Scenario.where(area_code: DELETED).delete_all
    end

    RENAMED.each do |old_name, new_name|
      rename_dataset(old_name, new_name)
    end
  end

  def down
    RENAMED.each do |new_name, old_name|
      rename_dataset(old_name, new_name)
    end
  end

  private

  def rename_dataset(old_name, new_name)
    say_with_time "#{old_name} -> #{new_name}" do
      Scenario.where(area_code: old_name).update_all(area_code: new_name)
    end
  end
end
