##
# Loading & Saving Scenarios
#
class Scenario < ActiveRecord::Base

  ##
  # Reset all values that can be changed by a user and influences GQL
  # to the default/empty values.
  #
  # @tested 2010-12-06 seb
  #
  def reset!
    self.user_values = {}
    self.update_statements = {}
    self.fce_settings = {}
    self.use_fce = false
  end
  alias_method :reset_user_values!, :reset!

  ##
  # Called from current. 
  #
  def load!
    build_update_statements
  end


  ##
  # Stores the current settings into the attributes. For when we want to save
  # the scenario in the db.
  #
  # @untested 2010-12-06 seb
  #
  def copy_scenario_state(scenario)
    self.user_values  = scenario.user_values.clone
    self.end_year     = scenario.end_year
    self.country      = scenario.country ? scenario.country.clone : nil
    self.region       = scenario.region ? scenario.region.clone : nil
    self.use_fce      = scenario.use_fce
  end
  
  # Returns a copy of a scenario. Used
  def clone!
    fresh = Scenario.new
    fresh.copy_scenario_state(self)
    fresh.title = self.title
    fresh.save
    fresh
  end
end