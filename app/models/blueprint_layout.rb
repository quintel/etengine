# == Schema Information
#
# Table name: blueprint_layouts
#
#  id         :integer(4)      not null, primary key
#  key        :string(255)
#  created_at :datetime
#  updated_at :datetime
#

# A BlueprintLayout is a visual layout of converters.
# It positions a Converter on a 2D map using ConverterPosition records.
# The BlueprintLayout is not directly connected to a Blueprint. Thus
# creating/editing/deleting blueprints and their converters have no impact
# on the BlueprintLayout. But if you visualize a blueprint with a
# BlueprintLayout that doesn't make sense, you just get a mess..
#
#
#
class BlueprintLayout < ActiveRecord::Base
  validates_presence_of :key

  has_many :converter_positions
end
