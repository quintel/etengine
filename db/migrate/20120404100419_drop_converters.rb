class DropConverters < ActiveRecord::Migration
  def self.up
    drop_table :converters
  end

  def self.down
  end
end
