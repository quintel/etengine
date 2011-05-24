require 'spec_helper'

describe Dataset::ConverterData do
  it { should belong_to :dataset }
  it { should belong_to :converter }
end

# == Schema Information
#
# Table name: dataset_converter_data
#
#  id                                                :integer(4)      not null, primary key
#  name                                              :string(255)
#  preset_demand                                     :integer(8)
#  created_at                                        :datetime
#  updated_at                                        :datetime
#  dataset_id                                        :integer(4)
#  converter_id                                      :integer(4)
#  demand_expected_value                             :integer(8)
#  typical_capacity_gross_in_mj_s                    :float
#  typical_capacity_effective_in_mj_s                :float
#  typical_thermal_capacity_effective_in_mj_yr       :float
#  max_capacity_factor                               :float
#  capacity_factor_emperical_scaling_excl            :float
#  land_use_in_nl                                    :float
#  technical_lifetime                                :float
#  technological_maturity                            :float
#  lead_time                                         :float
#  construction_time                                 :float
#  net_electrical_yield                              :float
#  net_heat_yield                                    :float
#  cost_om_fixed_per_mj                              :float
#  cost_om_variable_ex_fuel_co2_per_mj               :float
#  cost_co2_capture_ex_fuel_per_mj                   :float
#  cost_co2_transport_and_storage_per_mj             :float
#  cost_fuel_other_per_mj                            :float
#  overnight_investment_ex_co2_per_mj_s              :float
#  overnight_investment_co2_capture_per_mj           :float
#  sustainable                                       :float
#  mainly_baseload                                   :float
#  intermittent                                      :float
#  cost_co2_expected_per_mje                         :float
#  co2_production_kg_per_mj_output                   :float
#  use_id                                            :integer(4)
#  sector_id                                         :integer(4)
#  key                                               :string(255)
#  installed_capacity_effective_in_mj_s              :float
#  electricitiy_production_actual                    :float
#  wacc                                              :float
#  overnight_investment_co2_capture_per_mj_s         :float
#  capacity_factor                                   :float
#  co2_free                                          :float
#  comment                                           :text
#  simult_wd                                         :float
#  simult_sd                                         :float
#  simult_we                                         :float
#  simult_se                                         :float
#  peak_load_units_present                           :float
#  typical_electric_capacity                         :float
#  typical_heat_capacity                             :float
#  full_load_hours                                   :float
#  operation_hours                                   :float
#  operation_and_maintenance_cost_fixed              :float
#  operation_and_maintenance_cost_variable           :float
#  investment                                        :float
#  purchase_price                                    :float
#  installing_costs                                  :float
#  economic_lifetime                                 :float
#  municipality_demand                               :integer(8)
#  typical_input_capacity                            :float
#  fixed_operation_and_maintenance_cost_per_mw_input :float
#  residual_value_per_mw_input                       :float
#  decommissioning_costs_per_mw_input                :float
#  purchase_price_per_mw_input                       :float
#  installing_costs_per_mw_input                     :float
#  part_ets                                          :float
#

