class RemoveHabtmGqueryGroupAssociation < ActiveRecord::Migration
  def self.up
    drop_table :gqueries_gquery_groups
    add_column :gqueries, :gquery_group_id, :integer
    add_index :gqueries, :gquery_group_id
  end

  def self.down
    create_table :gqueries_gquery_groups, :id => false do |t|
      t.string :gquery_id
      t.string :gquery_group_id
    end
    add_index :gqueries_gquery_groups, [:gquery_id, :gquery_group_id]
    
    remove_column :gqueries, :gquery_group_id
  end
end
