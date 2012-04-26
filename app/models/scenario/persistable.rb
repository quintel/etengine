# Load, copy, reset and save
#
module Scenario::Persistable
  extend ActiveSupport::Concern

  # Reset all values that can be changed by a user and influences GQL
  # to the default/empty values.
  #
  # @tested 2010-12-06 seb
  #
  def reset!
    self.user_values = {}
    self.update_statements = {}
    self.update_statements_present = {}
    @inputs_present = {}
    @inputs_future = {}
    self.use_fce = false
  end

  # Called from current.
  #
  def load!
    build_update_statements
  end

  # Stores the current settings into the attributes. For when we want to save
  # the scenario in the db.
  #
  # @untested 2010-12-06 seb
  #
  def copy_scenario_state(scenario)
    self.user_values = scenario.user_values.clone
    self.end_year    = scenario.end_year
    self.area_code   = scenario.area_code
    self.use_fce     = scenario.use_fce
  end
end
