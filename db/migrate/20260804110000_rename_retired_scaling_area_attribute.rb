class RenameRetiredScalingAreaAttribute < ActiveRecord::Migration[7.1]
  # The area attribute ScenarioScaling uses. ETSource renamed it, and the scalings created before the
  # rename still hold the old name, which no dataset defines. ScenarioScaling#base_value reads the
  # attribute from the area whenever its own column is NULL, so those scalings have no multiplier and
  # raise whenever a value of theirs is scaled.
  OLD_ATTRIBUTE = 'number_of_residences'.freeze
  NEW_ATTRIBUTE = 'present_number_of_residences'.freeze

  def up
    say_with_time "#{OLD_ATTRIBUTE} -> #{NEW_ATTRIBUTE}" do
      ScenarioScaling.where(area_attribute: OLD_ATTRIBUTE).update_all(area_attribute: NEW_ATTRIBUTE)
    end
  end
end
