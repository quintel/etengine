class RemoveColorAttributesFromConverterPositions < ActiveRecord::Migration
  def self.up
    remove_column :converter_positions, :fill_color
    remove_column :converter_positions, :stroke_color
  end

  def self.down
    add_column :converter_positions, :stroke_color, :string
    add_column :converter_positions, :fill_color, :string
  end
end
