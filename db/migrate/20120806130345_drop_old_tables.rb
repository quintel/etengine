class DropOldTables < ActiveRecord::Migration
  def up
    drop_table :areas
    drop_table :carriers
    drop_table :graphs
    drop_table :inputs
  end

  def down
  end
end
