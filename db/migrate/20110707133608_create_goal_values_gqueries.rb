class CreateGoalValuesGqueries < ActiveRecord::Migration
  def self.up
    Gquery.create :key => 'policy_goal_co2_emission_user_value',             :unit => 'MT', :query => 'GOAL_USER_VALUE(co2_emission)'
    Gquery.create :key => 'policy_goal_net_energy_import_user_value',        :unit => 'factor', :query => 'GOAL_USER_VALUE(net_energy_import)'
    Gquery.create :key => 'policy_goal_net_electricity_import_user_value',   :unit => 'factor', :query => 'GOAL_USER_VALUE(net_electricity_import)'
    Gquery.create :key => 'policy_goal_total_energy_cost_user_value',        :unit => 'euro', :query => 'GOAL_USER_VALUE(total_energy_cost)'
    Gquery.create :key => 'policy_goal_electricity_cost_user_value',         :unit => 'euro', :query => 'GOAL_USER_VALUE(electricity_cost)'
    Gquery.create :key => 'policy_goal_renewable_percentage_user_value',     :unit => 'factor', :query => 'GOAL_USER_VALUE(renewable_percentage)'
    Gquery.create :key => 'policy_goal_onshore_land_user_value',             :unit => 'km2', :query => 'GOAL_USER_VALUE(onshore_land)'
    Gquery.create :key => 'policy_goal_onshore_coast_user_value',            :unit => 'km', :query => 'GOAL_USER_VALUE(onshore_coast)'
    Gquery.create :key => 'policy_goal_offshore_user_value',                 :unit => 'km2', :query => 'GOAL_USER_VALUE(offshore)'
    Gquery.create :key => 'policy_goal_roofs_for_solar_panels_user_value',   :unit => 'km2', :query => 'GOAL_USER_VALUE(roofs_for_solar_panels)'
    Gquery.create :key => 'policy_goal_land_for_solar_panels_user_value',    :unit => 'km2', :query => 'GOAL_USER_VALUE(land_for_solar_panels)'
    Gquery.create :key => 'policy_goal_land_for_csp_user_value',             :unit => 'km2', :query => 'GOAL_USER_VALUE(land_for_csp)'
    Gquery.create :key => 'policy_goal_co2_emission_target_value',           :unit => 'MT', :query => 'GOAL(co2_emission)'
    Gquery.create :key => 'policy_goal_net_energy_import_target_value',      :unit => 'factor', :query => 'GOAL(net_energy_import)'
    Gquery.create :key => 'policy_goal_net_electricity_import_target_value', :unit => 'factor', :query => 'GOAL(net_electricity_import)'
    Gquery.create :key => 'policy_goal_total_energy_cost_target_value',      :unit => 'euro', :query => 'GOAL(total_energy_cost)'
    Gquery.create :key => 'policy_goal_electricity_cost_target_value',       :unit => 'euro', :query => 'GOAL(electricity_cost)'
    Gquery.create :key => 'policy_goal_renewable_percentage_target_value',   :unit => 'factor', :query => 'GOAL(renewable_percentage)'
    Gquery.create :key => 'policy_goal_onshore_land_target_value',           :unit => 'km2', :query => 'GOAL(onshore_land)'
    Gquery.create :key => 'policy_goal_onshore_coast_target_value',          :unit => 'km', :query => 'GOAL(onshore_coast)'
    Gquery.create :key => 'policy_goal_offshore_target_value',               :unit => 'km2', :query => 'GOAL(offshore)'
    Gquery.create :key => 'policy_goal_roofs_for_solar_panels_target_value', :unit => 'km2', :query => 'GOAL(roofs_for_solar_panels)'
    Gquery.create :key => 'policy_goal_land_for_solar_panels_target_value',  :unit => 'km2', :query => 'GOAL(land_for_solar_panels)'
    Gquery.create :key => 'policy_goal_land_for_csp_target_value',           :unit => 'km2', :query => 'GOAL(land_for_csp)'
  end

  def self.down
    Gquery.find_by_key('policy_goal_co2_emission_user_value').destroy
    Gquery.find_by_key('policy_goal_net_energy_import_user_value').destroy
    Gquery.find_by_key('policy_goal_net_electricity_import_user_value').destroy
    Gquery.find_by_key('policy_goal_total_energy_cost_user_value').destroy       
    Gquery.find_by_key('policy_goal_electricity_cost_user_value').destroy        
    Gquery.find_by_key('policy_goal_renewable_percentage_user_value').destroy    
    Gquery.find_by_key('policy_goal_onshore_land_user_value').destroy            
    Gquery.find_by_key('policy_goal_onshore_coast_user_value').destroy           
    Gquery.find_by_key('policy_goal_offshore_user_value').destroy                
    Gquery.find_by_key('policy_goal_roofs_for_solar_panels_user_value').destroy  
    Gquery.find_by_key('policy_goal_land_for_solar_panels_user_value').destroy   
    Gquery.find_by_key('policy_goal_land_for_csp_user_value').destroy            
    Gquery.find_by_key('policy_goal_co2_emission_target_value').destroy          
    Gquery.find_by_key('policy_goal_net_energy_import_target_value').destroy     
    Gquery.find_by_key('policy_goal_net_electricity_import_target_value').destroy
    Gquery.find_by_key('policy_goal_total_energy_cost_target_value').destroy     
    Gquery.find_by_key('policy_goal_electricity_cost_target_value').destroy      
    Gquery.find_by_key('policy_goal_renewable_percentage_target_value').destroy  
    Gquery.find_by_key('policy_goal_onshore_land_target_value').destroy          
    Gquery.find_by_key('policy_goal_onshore_coast_target_value').destroy         
    Gquery.find_by_key('policy_goal_offshore_target_value').destroy              
    Gquery.find_by_key('policy_goal_roofs_for_solar_panels_target_value').destroy
    Gquery.find_by_key('policy_goal_land_for_solar_panels_target_value').destroy 
    Gquery.find_by_key('policy_goal_land_for_csp_target_value').destroy          
  end
end
