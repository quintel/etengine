class DropEnergyBalanceGroup < ActiveRecord::Migration
  def up
    drop_table :energy_balance_groups
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
