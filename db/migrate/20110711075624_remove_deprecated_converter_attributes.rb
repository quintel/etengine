class RemoveDeprecatedConverterAttributes < ActiveRecord::Migration
  def self.up
    remove_column :dataset_converter_data, :capacity_factor_emperical_scaling_excl
    remove_column :dataset_converter_data, :net_electrical_yield
    remove_column :dataset_converter_data, :net_heat_yield
  end

  def self.down
    add_column :dataset_converter_data, :net_heat_yield, :float
    add_column :dataset_converter_data, :net_electrical_yield, :float
    add_column :dataset_converter_data, :capacity_factor_emperical_scaling_excl, :float
  end
end
