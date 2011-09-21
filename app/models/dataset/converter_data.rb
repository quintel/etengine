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
