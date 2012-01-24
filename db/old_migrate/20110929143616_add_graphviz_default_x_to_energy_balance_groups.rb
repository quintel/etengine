class AddGraphvizDefaultXToEnergyBalanceGroups < ActiveRecord::Migration
  def self.up
    add_column :energy_balance_groups, :graphviz_default_x, :integer
  end

  def self.down
    remove_column :energy_balance_groups, :graphviz_default_x
  end
end
