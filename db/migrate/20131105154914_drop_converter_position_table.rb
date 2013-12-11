class DropConverterPositionTable < ActiveRecord::Migration
  def up
    drop_table :converter_positions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
