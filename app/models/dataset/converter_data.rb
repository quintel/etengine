# == Schema Information
#
# Table name: dataset_converter_data
#
#  id                                                         :integer(4)      not null, primary key
#  name                                                       :string(255)
#  preset_demand                                              :integer(8)
#  created_at                                                 :datetime
#  updated_at                                                 :datetime
#  dataset_id                                                 :integer(4)
#  converter_id                                               :integer(4)
#  demand_expected_value                                      :integer(8)
#  network_capacity_available_in_mw                           :float
#  network_capacity_used_in_mw                                :float
#  land_use_per_unit                                          :float
#  technical_lifetime                                         :float
#  lead_time                                                  :float
#  construction_time                                          :float
#  costs_per_mj                                               :float
#  network_expansion_costs_in_euro_per_mw                     :float
#  use_id                                                     :integer(4)
#  sector_id                                                  :integer(4)
#  key                                                        :string(255)
#  wacc                                                       :float
#  capacity_factor                                            :float
#  co2_free                                                   :float
#  simult_wd                                                  :float
#  simult_sd                                                  :float
#  simult_we                                                  :float
#  simult_se                                                  :float
#  peak_load_units_present                                    :float
#  full_load_hours                                            :float
#  operation_and_maintenance_cost_fixed_per_mw_input          :float
#  operation_and_maintenance_cost_variable_per_full_load_hour :float
#  municipality_demand                                        :integer(8)
#  typical_nominal_input_capacity                             :float
#  residual_value_per_mw_input                                :float
#  decommissioning_costs_per_mw_input                         :float
#  purchase_price_per_mw_input                                :float
#  installing_costs_per_mw_input                              :float
#  part_ets                                                   :float
#  ccs_investment_per_mw_input                                :float
#  ccs_operation_and_maintenance_cost_per_full_load_hour      :float
#  decrease_in_nomimal_capacity_over_lifetime                 :float
#  availability                                               :float
#  variability                                                :float
#

# TODO seb : rename preset_demand, remove hacked_attributes (2010-08-19)
# Data for converters belonging to a specific graph instance
#
#
#
#
# == Guide: How to add new attributes to ConverterData
#
# * Make a new migration
#
# Add all the attributes into the ConverterData table. Numbers are usually stored
# as floats. Because when we do calculations, especially divisions, with those numbers
# integer rounds values up.
#
# add_column :converter_datas, :new_attr, ...
#
# * Annotate models
#
# So that we don't have to check schema.rb we annotate our models with
# the table attributes. Check the bottom of this file.
#
# rake annotate
#
# * Add attributes to {Qernel::ConverterApi::ATTRIBUTES_USED}
#
# Add them into the array ATTRIBUTES_USED so that they will be added to the attributes.
# This will load the attributes into our Qernel Converter. Attributes that are not in
# ATTRIBUTES_USED will be ignored by the Qernel.
#
# * The attributes can now be accessed with the GQL
#
#
#
class Dataset::ConverterData < ActiveRecord::Base
  include Dataset::TouchOnUpdate

  belongs_to :dataset
  belongs_to :converter
  
  validates :dataset, :presence => true
  validates :converter, :presence => true

  def dataset_key
    Qernel::Converter.compute_dataset_key(converter_id)
  end

  ##
  # See {Qernel::Converter} section demand and preset_demand on why we have
  # to add {'demand' => preset_demand}
  #
  def dataset_attributes
    attrs = Qernel::ConverterApi::ATTRIBUTES_USED.inject({}) do |hsh, key|
      hsh.merge(key => self[key])
    end
    attrs[:demand] = self.preset_demand
    attrs[:preset_demand] = self.preset_demand
    attrs
  end
end
