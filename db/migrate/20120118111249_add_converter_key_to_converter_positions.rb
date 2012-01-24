class AddConverterKeyToConverterPositions < ActiveRecord::Migration
  def self.up
    add_column :converter_positions, :converter_key, :string

    ConverterPosition.all.each do |position|
      position.update_attribute :converter_key, position.converter.full_key
    end
  end

  def self.down
    remove_column :converter_positions, :converter_key
  end
end
