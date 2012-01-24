class CreateGqueriesForPeakLaod < ActiveRecord::Migration
  def self.up
    Gquery.create :key => 'peak_load_check_lv',    :query => 'peak_load_lvfuture:GREATER(Q(investment_cost_lv_net_total),0)'                              
    Gquery.create :key => 'peak_load_check_mv-lv', :query => 'future:GREATER(Q(investment_cost_mv_lv_transformer_total),0)'                              
    Gquery.create :key => 'peak_load_check_mv'   , :query => 'future:GREATER(SUM(Q(investment_cost_mv_distribution_net_total),Q(investment_cost_mv_transport_net_total)),0)'                              
    Gquery.create :key => 'peak_load_check_hv-mv', :query => 'future:GREATER(Q(investment_cost_hv_mv_transformer_total),0)'                              
    Gquery.create :key => 'peak_load_check_hv'   , :query => 'future:GREATER(Q(investment_cost_hv_net_total),0)'
    Gquery.create :key => 'peak_load_check_total', :query => 'future:Q(grid_investment_needed)'
  end

  def self.down
    Gquery.find_by_key('peak_load_check_lv'   ).destroy
    Gquery.find_by_key('peak_load_check_mv-lv').destroy
    Gquery.find_by_key('peak_load_check_mv'   ).destroy
    Gquery.find_by_key('peak_load_check_hv-mv').destroy
    Gquery.find_by_key('peak_load_check_hv'   ).destroy
    Gquery.find_by_key('peak_load_check_total').destroy
  end
end
