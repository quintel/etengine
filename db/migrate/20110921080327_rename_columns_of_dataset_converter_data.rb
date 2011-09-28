class RenameColumnsOfDatasetConverterData < ActiveRecord::Migration
  def self.up
    rename_column :dataset_converter_data, :typical_capacity_gross_in_mj_s,         :network_capacity_available_in_mw
    rename_column :dataset_converter_data, :typical_capacity_effective_in_mj_s,     :network_capacity_used_in_mw
    rename_column :dataset_converter_data, :overnight_investment_ex_co2_per_mj_s,   :network_expansion_costs_in_euro_per_mw
    rename_column :dataset_converter_data, :cost_om_fixed_per_mj,                   :costs_per_mj
  end

  def self.down
    rename_column :dataset_converter_data, :network_capacity_available_in_mw,       :typical_capacity_gross_in_mj_s
    rename_column :dataset_converter_data, :network_capacity_used_in_mw,            :typical_capacity_effective_in_mj_s
    rename_column :dataset_converter_data, :network_expansion_costs_in_euro_per_mw, :overnight_investment_ex_co2_per_mj_s
    rename_column :dataset_converter_data, :costs_per_mj,                           :cost_om_fixed_per_mj
  end
end
