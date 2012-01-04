class RenameNomimalIntoNominal < ActiveRecord::Migration
  def self.up
    rename_column :dataset_converter_data,
      :decrease_in_nomimal_capacity_over_lifetime,
      :decrease_in_nominal_capacity_over_lifetime
  end

  def self.down
    rename_column :dataset_converter_data,
      :decrease_in_nominal_capacity_over_lifetime,
      :decrease_in_nominal_capacity_over_lifetime
  end
end
