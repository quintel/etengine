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
  def copy_scenario_state(preset)
    self.user_values.reverse_merge!(preset.user_values.clone)
    self.end_year    = preset.end_year
    self.area_code   = preset.area_code
    self.use_fce     = preset.use_fce
  end
end
