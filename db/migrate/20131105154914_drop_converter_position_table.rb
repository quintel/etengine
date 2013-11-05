class DropConverterPositionTable < ActiveRecord::Migration
  def up
    hash = ConverterPosition.all.inject({}) do |mem, el|
      mem[el.converter_key] = { x: el.x, y: el.y }
      mem
    end

    File.open('config/converter_positions.yml', 'w') do |f|
      f.write hash.to_yaml
    end

    drop_table :converter_positions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
