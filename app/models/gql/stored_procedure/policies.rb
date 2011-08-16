module Gql

##
# StoredProcedure is to Graph/Qernel what a stored procedure is to a database. These 'canned' queries
# can be expressed with a simple syntax such as 'stored:present_area'
#
# == Useage
#
#   Current.gql.query('stored:policy_electricity_cost')
#
class StoredProcedure
  # TODO: reimplement and simplify related js code on the ETM
  # the number of user-defined policy targets met today (?) and met in the future
  # do we need today targets? I'd use future targets only - PZ Thu 23 Jun 2011 14:36:23 CEST
  def policy_targets_met
    Current.gql.policy.goals.count{|x| x.reached?}
  end

  def policy_targets_set
    Current.gql.policy.goals.count{|x| !x.user_value.nil?}
  end

  # TODO: add procedures to get a hash of data for the policy goals,
  # something to return a hash like this:
  # { :key => 'co2_emission',
  #   :goal_value => 123, # nil if the goal has not been set
  #   :current_value => 234,
  #   :success => true|false
  # }

  ##
  # attributes of the area as presently defined
  #
  def present_area
    Current.gql.policy.present_area
  end

  # present and target values for total_energy_cost
  def policy_total_energy_cost
    absolute_result_for(:total_energy_cost)
  end

  # present and target values for electricity_cost
  def policy_electricity_cost
    absolute_result_for(:electricity_cost)
  end

  # present and target values for co2_emission
  def policy_co2_emission
    absolute_result_for(:co2_emission)
  end

  # present and target values for renewable_percentage
  def policy_renewable_percentage
    percentage_result_for(:renewable_percentage)
  end

  # present and target values for onshore_land, expressed as a percentage
  def policy_onshore_land
    percentage_result_for(:onshore_land, present_area.onshore_suitable_for_wind)
  end

  # present and target values for onshore_coast
  def policy_onshore_coast
    percentage_result_for(:onshore_coast, present_area.coast_line)
  end

  # present and target values for offshore
  def policy_offshore
    percentage_result_for(:offshore, present_area.offshore_suitable_for_wind)
  end

  # present and target values for roofs_for_solar_panels
  def policy_roofs_for_solar_panels
    percentage_result_for(:roofs_for_solar_panels, present_area.roof_surface_available_pv)
  end

  # present and target values for land_for_solar_panels
  def policy_land_for_solar_panels
    percentage_result_for(:land_for_solar_panels, present_area.land_available_for_solar)
  end

  # present and target values for land_for_csp
  def policy_land_for_csp
    percentage_result_for(:land_for_csp, present_area.land_available_for_solar)
  end

  # present and target values for greengas
  def policy_greengas
    percentage_result_for(:greengas, present_area.areable_land)
  end

  # present and target values for biomass
  def policy_biomass
    percentage_result_for(:biomass, present_area.areable_land)
  end

  # present and target values for net_energy_import
  def policy_net_energy_import
    percentage_result_for(:net_energy_import)
  end

  # present and target values for net_electricity_import
  def policy_net_electricity_import
    percentage_result_for(:net_electricity_import)
  end

private
  # These queries are used to format vertical bars (see output_elements/vertical_stacked_bar.rb)
  # for display using totals or percentages of land use for some policy. They use goal.target_value
  # in a different way than PolicyGoalFormatter.output_user_target, which is used to display
  # constraints either as absolute target values or user_values (in the case of co2, net_*_import, and
  # renewable_percentage).

  ##
  # provides query result in absolute terms
  #
  def absolute_result_for(goal)
    policy_result_for(Current.gql.policy.goal(goal), 1)
  end

  # provides query result in percentage terms
  def percentage_result_for(goal, divisor=1)
    policy_result_for(Current.gql.policy.goal(goal), 100 / divisor)
  end

  def policy_result_for(policy_goal, multiplier)
    ResultSet.create [
      #NEW: when no goal is initialized it should return 0
      [Current.scenario.start_year, (policy_goal ? policy_goal.start_value * multiplier : 0)],
      [Current.scenario.end_year, (policy_goal ? policy_goal.target_value * multiplier : 0 )]
    ]
  end

end

end
