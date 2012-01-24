class AddUpdateLocationToInputs < ActiveRecord::Migration
  def self.up
    add_column :inputs, :updateable_period, :string, :default => 'future', :null => false
  end

  def self.down
    remove_column :inputs, :updateable_period
  end
end
