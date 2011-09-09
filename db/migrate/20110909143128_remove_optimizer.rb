class RemoveOptimizer < ActiveRecord::Migration
  def self.up
    remove_column :gqueries, :usable_for_optimizer
  end

  def self.down
    add_column :gqueries, :usable_for_optimizer, :boolean, :default => false
  end
end
