class MissingMixerGquery < ActiveRecord::Migration
  def self.up
    Gquery.create :key => "co2_emission_percent_change_from_1990_corrected_for_electricity_import",
                  :unit => '%',
                  :query => "DIVIDE(\r\n       SUM(\r\n            DIVIDE(\r\n                   Q(co2_emission_total),\r\n                   BILLIONS\r\n                   )\r\n           ,NEG(AREA(co2_emission_1990))\r\n           )\r\n          ,\r\n       AREA(co2_emission_1990)\r\n       )"
  end

  def self.down
    Gquery.find_by_key("co2_emission_percent_change_from_1990_corrected_for_electricity_import").destroy
  end
end
