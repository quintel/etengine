class RenamePeakLoadQueries < ActiveRecord::Migration
  def self.up
    Gquery.find_by_key('peak_load_check_mv-lv').update_attribute :key, 'peak_load_check_mv_lv'
    Gquery.find_by_key('peak_load_check_hv-mv').update_attribute :key, 'peak_load_check_hv_mv'
  end

  def self.down
    Gquery.find_by_key('peak_load_check_mv_lv').update_attribute :key, 'peak_load_check_mv-lv'
    Gquery.find_by_key('peak_load_check_hv_mv').update_attribute :key, 'peak_load_check_hv-mv'
  end
end
