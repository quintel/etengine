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
    # @inputs_present/future have to be nil, not an empty hash. otherwise
    # the memoized def inputs_present will not pick up the changes. 
    @inputs_present  = nil
    @inputs_future   = nil
    self.use_fce = false
  end

  # Stores the current settings into the attributes. For when we want to save
  # the scenario in the db.
  #
  # @untested 2010-12-06 seb
  #
  def copy_scenario_state(preset)
    self.user_values.reverse_merge!(preset.user_values.clone)

    if preset.respond_to?(:balanced_values)
      self.balanced_values.reverse_merge!(preset.balanced_values.clone)
    end

    self.end_year    = preset.end_year
    self.area_code   = preset.area_code
    self.use_fce     = preset.use_fce
  end
end
