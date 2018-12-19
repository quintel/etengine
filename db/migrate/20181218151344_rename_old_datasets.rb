class RenameOldDatasets < ActiveRecord::Migration[5.1]
  NAMES = {
    GM0393_haarlemmerliede_en_spaarnwoude: :GM0394_haarlemmermeer,
    flevoland: :PV24_flevoland,
    friesland: :PV21_friesland,
    noorderplantsoen: :BU00140201_noorderplantsoenbuurt,
    reitdiep: :BU00140904_reitdiep,
    stichtse_vecht: :GM1904_stichtse_vecht
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
