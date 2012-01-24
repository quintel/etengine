class CreateNewGqueryForElectricityTarget < ActiveRecord::Migration
  def self.up
    if g1 = Gquery.find_by_key('chart_demand_41_electricity_production')
      g1.update_attributes :key => 'chart_demand_41_electricity_production_present'
    end
    g2 = Gquery.create! :key => 'chart_demand_41_electricity_production_future', :query => "future:DIVIDE(SUM(V(GROUP(final_demand_cbs);input_of_electricity),V(grid_losses_electricity_energy;demand),NEG(Q(electricity_export_losses))),BILLIONS)"
  end

  def self.down
  end
end
