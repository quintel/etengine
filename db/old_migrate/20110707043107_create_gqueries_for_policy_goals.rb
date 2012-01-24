class CreateGqueriesForPolicyGoals < ActiveRecord::Migration
  def self.up
    Gquery.create :key => "policy_goal_co2_emission_start_value", :query => 'UNIT(Q(co2_emission_total);billions)'
    Gquery.create :key => "policy_goal_co2_emission_reached", :query => 'LESS_OR_EQUAL(UNIT(Q(co2_emission_total);billions),GOAL(co2_emission))'
    Gquery.create :key => "policy_goal_net_energy_import_start_value", :query => 'Q(energy_dependence)'
    Gquery.create :key => "policy_goal_net_energy_import_reached", :query => 'LESS_OR_EQUAL(Q(energy_dependence),GOAL(net_energy_import))'
    Gquery.create :key => "policy_goal_net_electricity_import_start_value", :query => 'Q(electricity_dependence)'
    Gquery.create :key => "policy_goal_net_electricity_import_reached", :query => 'LESS_OR_EQUAL(Q(electricity_dependence),GOAL(net_electricity_import))'
    Gquery.create :key => "policy_goal_total_energy_cost_start_value", :query => 'UNIT(Q(cost_total);billions)'
    Gquery.create :key => "policy_goal_total_energy_cost_reached", :query => 'LESS_OR_EQUAL(UNIT(Q(cost_total);billions),GOAL(total_energy_cost))'
    Gquery.create :key => "policy_goal_electricity_cost_start_value", :query => 'PRODUCT(SECS_PER_HOUR,Q(avg_total_cost_for_electricity_production_per_mj))'
    Gquery.create :key => "policy_goal_electricity_cost_reached", :query => 'LESS_OR_EQUAL(PRODUCT(SECS_PER_HOUR,Q(avg_total_cost_for_electricity_production_per_mj)),GOAL(electricity_cost))'
    Gquery.create :key => "policy_goal_renewable_percentage_start_value", :query => 'Q(share_of_renewable_energy)'
    Gquery.create :key => "policy_goal_renewable_percentage_reached", :query => 'GREATER_OR_EQUAL(Q(share_of_renewable_energy),GOAL(renewable_percentage))'
    Gquery.create :key => "policy_goal_onshore_land_start_value", :query => 'UNIT(DIVIDE(V(wind_inland_energy;total_land_use),AREA(onshore_suitable_for_wind));percentage)'
    Gquery.create :key => "policy_goal_onshore_land_reached", :query => 'LESS_OR_EQUAL(V(wind_inland_energy;total_land_use),GOAL(onshore_land))'
    Gquery.create :key => "policy_goal_onshore_coast_start_value", :query => 'UNIT(DIVIDE(V(wind_coastal_energy;total_land_use),AREA(offshore_suitable_for_wind));percentage)'
    Gquery.create :key => "policy_goal_onshore_coast_reached", :query => 'LESS_OR_EQUAL(V(wind_coastal_energy;total_land_use),GOAL(onshore_coast))'
    Gquery.create :key => "policy_goal_offshore_start_value", :query => 'UNIT(DIVIDE(V(wind_offshore_energy;total_land_use),AREA(offshore_suitable_for_wind));percentage)'
    Gquery.create :key => "policy_goal_offshore_reached", :query => 'LESS_OR_EQUAL(V(wind_offshore_energy;total_land_use),GOAL(offshore))'
    Gquery.create :key => "policy_goal_roofs_for_solar_panels_start_value", :query => 'Q(roof_pv_percentage_used)'
    Gquery.create :key => "policy_goal_roofs_for_solar_panels_reached", :query => 'LESS_OR_EQUAL(V(local_solar_pv_grid_connected_energy_energetic;total_land_use),GOAL(roofs_for_solar_panels))'
    Gquery.create :key => "policy_goal_land_for_solar_panels_start_value", :query => 'Q(land_pv_percentage_used)'
    Gquery.create :key => "policy_goal_land_for_solar_panels_reached", :query => 'LESS_OR_EQUAL(V(solar_pv_central_production_energy_energetic;total_land_use),GOAL(land_for_solar_panels))'
    Gquery.create :key => "policy_goal_land_for_csp_start_value", :query => 'Q(land_csp_percentage_used)'
    Gquery.create :key => "policy_goal_land_for_csp_reached", :query => 'LESS_OR_EQUAL(V(solar_csp_energy;total_land_use),GOAL(land_for_csp))'

    Gquery.create :key => 'policy_goal_co2_emission_value', :query => 'UNIT(Q(co2_emission_total);billions)'
    Gquery.create :key => 'policy_goal_net_energy_import_value', :query => 'Q(energy_dependence)'
    Gquery.create :key => 'policy_goal_net_electricity_import_value', :query => 'Q(electricity_dependence)'
    Gquery.create :key => 'policy_goal_total_energy_cost_value', :query => 'UNIT(Q(cost_total);billions)'
    Gquery.create :key => 'policy_goal_electricity_cost_value', :query => 'PRODUCT(SECS_PER_HOUR,Q(avg_total_cost_for_electricity_production_per_mj))'
    Gquery.create :key => 'policy_goal_renewable_percentage_value', :query => 'Q(share_of_renewable_energy)'
    Gquery.create :key => 'policy_goal_onshore_land_value', :query => 'Q(onshore_land)'
    Gquery.create :key => 'policy_goal_onshore_coast_value', :query => 'Q(onshore_coast)'
    Gquery.create :key => 'policy_goal_offshore_value', :query => 'Q(offshore)'
    Gquery.create :key => 'policy_goal_roofs_for_solar_panels_value', :query => 'SUM(V(solar_panels_buildings_energetic,local_solar_pv_grid_connected_energy_energetic;total_land_use))'
    Gquery.create :key => 'policy_goal_land_for_solar_panels_value', :query => 'V(solar_pv_central_production_energy_energetic;total_land_use)'
    Gquery.create :key => 'policy_goal_land_for_csp_value', :query => 'V(solar_csp_energy;total_land_use)'

  end

  def self.down
    %w[
      policy_goal_co2_emission_start_value          
      policy_goal_co2_emission_reached              
      policy_goal_net_energy_import_start_value     
      policy_goal_net_energy_import_reached         
      policy_goal_net_electricity_import_start_value
      policy_goal_net_electricity_import_reached    
      policy_goal_total_energy_cost_start_value     
      policy_goal_total_energy_cost_reached         
      policy_goal_electricity_cost_start_value      
      policy_goal_electricity_cost_reached          
      policy_goal_renewable_percentage_start_value  
      policy_goal_renewable_percentage_reached      
      policy_goal_onshore_land_start_value          
      policy_goal_onshore_land_reached              
      policy_goal_onshore_coast_start_value         
      policy_goal_onshore_coast_reached             
      policy_goal_offshore_start_value              
      policy_goal_offshore_reached                  
      policy_goal_roofs_for_solar_panels_start_value
      policy_goal_roofs_for_solar_panels_reached    
      policy_goal_land_for_solar_panels_start_value 
      policy_goal_land_for_solar_panels_reached     
      policy_goal_land_for_csp_start_value          
      policy_goal_land_for_csp_reached        
       
      policy_goal_co2_emission_value
      policy_goal_net_energy_import_value
      policy_goal_net_electricity_import_value
      policy_goal_total_energy_cost_value
      policy_goal_electricity_cost_value
      policy_goal_renewable_percentage_value
      policy_goal_onshore_land_value
      policy_goal_onshore_coast_value
      policy_goal_offshore_value
      policy_goal_roofs_for_solar_panels_value
      policy_goal_land_for_solar_panels_value
      policy_goal_land_for_csp_value
    ].each do |key|
      Gquery.find_by_key(key).destroy
    end
  end
end
