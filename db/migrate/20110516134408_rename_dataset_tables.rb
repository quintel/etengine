class RenameDatasetTables < ActiveRecord::Migration
  def self.up
    rename_table :carrier_datas, :dataset_carrier_data
    rename_table :link_datas, :dataset_link_data
    rename_table :slot_datas, :dataset_slot_data
    rename_table :converter_datas, :dataset_converter_data
  end

  def self.down
    rename_table :dataset_carrier_data, :carrier_datas
    rename_table :dataset_link_data, :link_datas
    rename_table :dataset_slot_data, :slot_datas
    rename_table :dataset_converter_data, :converter_datas
  end
end
