class RemoveBlackboxes < ActiveRecord::Migration
  def self.up
    drop_table :blackboxes
    drop_table :blackbox_gqueries
    # drop_table :blackbox_input_elements
    drop_table :blackbox_scenarios
    drop_table :blackbox_output_series
  end

  def self.down
  end
end
