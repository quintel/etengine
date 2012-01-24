class CreatePresentUpdatetAtToInputs < ActiveRecord::Migration
  def self.up
    add_column :scenarios, :present_updated_at, :timestamp
  end

  def self.down
    remove_column :scenarios, :present_updated_at
  end
end