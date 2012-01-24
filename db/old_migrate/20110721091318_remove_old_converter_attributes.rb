class RemoveOldConverterAttributes < ActiveRecord::Migration
  def self.up
    remove_column :dataset_converter_data, :technological_maturity
    remove_column :dataset_converter_data, :typical_thermal_capacity_effective_in_mj_yr
    remove_column :dataset_converter_data, :cost_co2_expected_per_mje
    remove_column :dataset_converter_data, :investment
    remove_column :dataset_converter_data, :fixed_operation_and_maintenance_cost_per_mw_input
    remove_column :dataset_converter_data, :purchase_price
    remove_column :dataset_converter_data, :installing_costs
  end

  def self.down
    add_column :dataset_converter_data, :installing_costs, :float
    add_column :dataset_converter_data, :purchase_price, :float
    add_column :dataset_converter_data, :typical_thermal_capacity_effective_in_mj_yr, :float
    add_column :dataset_converter_data, :technological_maturity, :float
    add_column :dataset_converter_data, :cost_co2_expected_per_mje, :float
    add_column :dataset_converter_data, :investment, :float
    add_column :dataset_converter_data, :fixed_operation_and_maintenance_cost_per_mw_input, :float
  end
end