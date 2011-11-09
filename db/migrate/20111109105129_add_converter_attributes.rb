class AddConverterAttributes < ActiveRecord::Migration
  def self.up
    add_column :dataset_converter_data, :availability, :float
    add_column :dataset_converter_data, :variability, :float
  end

  def self.down
    remove_column :dataset_converter_data, :availability
    remove_column :dataset_converter_data, :variability
  end
end
