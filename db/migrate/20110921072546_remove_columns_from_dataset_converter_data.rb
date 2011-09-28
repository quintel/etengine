class RemoveColumnsFromDatasetConverterData < ActiveRecord::Migration
  def self.up
    remove_column :dataset_converter_data, :max_capacity_factor
    remove_column :dataset_converter_data, :cost_om_variable_ex_fuel_co2_per_mj
    remove_column :dataset_converter_data, :cost_co2_capture_ex_fuel_per_mj
    remove_column :dataset_converter_data, :cost_co2_transport_and_storage_per_mj
    remove_column :dataset_converter_data, :cost_fuel_other_per_mj
    remove_column :dataset_converter_data, :overnight_investment_co2_capture_per_mj
    remove_column :dataset_converter_data, :mainly_baseload
    remove_column :dataset_converter_data, :intermittent
    remove_column :dataset_converter_data, :typical_electric_capacity
    remove_column :dataset_converter_data, :typical_heat_capacity
    remove_column :dataset_converter_data, :operation_hours
    remove_column :dataset_converter_data, :sustainable
    remove_column :dataset_converter_data, :installed_capacity_effective_in_mj_s
    remove_column :dataset_converter_data, :electricitiy_production_actual
    remove_column :dataset_converter_data, :overnight_investment_co2_capture_per_mj_s
    remove_column :dataset_converter_data, :economic_lifetime
    remove_column :dataset_converter_data, :co2_production_kg_per_mj_output
    
    remove_column :dataset_converter_data, :comment
  end

  def self.down
    add_column :dataset_converter_data, :max_capacity_factor                         ,:float
    add_column :dataset_converter_data, :cost_om_variable_ex_fuel_co2_per_mj         ,:float
    add_column :dataset_converter_data, :cost_co2_capture_ex_fuel_per_mj             ,:float
    add_column :dataset_converter_data, :cost_co2_transport_and_storage_per_mj       ,:float
    add_column :dataset_converter_data, :cost_fuel_other_per_mj                      ,:float
    add_column :dataset_converter_data, :overnight_investment_co2_capture_per_mj     ,:float
    add_column :dataset_converter_data, :mainly_baseload                             ,:float
    add_column :dataset_converter_data, :intermittent                                ,:float
    add_column :dataset_converter_data, :typical_electric_capacity                   ,:float
    add_column :dataset_converter_data, :typical_heat_capacity                       ,:float
    add_column :dataset_converter_data, :operation_hours                             ,:float
    add_column :dataset_converter_data, :sustainable                                 ,:float
    add_column :dataset_converter_data, :installed_capacity_effective_in_mj_s        ,:float
    add_column :dataset_converter_data, :electricitiy_production_actual              ,:float
    add_column :dataset_converter_data, :overnight_investment_co2_capture_per_mj_s   ,:float
    add_column :dataset_converter_data, :economic_lifetime                           ,:float
    add_column :dataset_converter_data, :co2_production_kg_per_mj_output             ,:float
    
    add_column :dataset_converter_data, :comment                                     ,:text
  end
end