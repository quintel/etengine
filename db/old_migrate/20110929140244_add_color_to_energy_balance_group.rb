class AddColorToEnergyBalanceGroup < ActiveRecord::Migration
  def self.up
    add_column :energy_balance_groups, :graphviz_color, :string
  end

  def self.down
    remove_column :energy_balance_groups, :graphviz_color
  end
end
