class RemoveOldNoardeastFryslanMunicipalities < ActiveRecord::Migration[5.2]
  OLD_NAMES = [
  	"GM0058_dongeradeel",
  	"GM0079_kollumerland_en_nieuwkruisland",
  	"GM1722_ferwerderadiel"
  ].freeze

  NEW_NAME = "GM1970_noardeast_fryslan"

  def up
    OLD_NAMES.each do |name|
      say_with_time "#{name} -> #{NEW_NAME}" do
        Scenario.where(area_code: name).update_all(area_code: NEW_NAME)
      end
    end
  end

  def down
    # Nothing to do.
  end
end
