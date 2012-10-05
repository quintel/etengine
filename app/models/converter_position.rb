# == Schema Information
#
# Table name: converter_positions
#
#  id                  :integer(4)      not null, primary key
#  converter_id        :integer(4)
#  x                   :integer(4)
#  y                   :integer(4)
#  created_at          :datetime
#  updated_at          :datetime
#  hidden              :boolean(1)
#  blueprint_layout_id :integer(4)
#  converter_key       :string(255)
#

##
# This class stores x,y values for the new online sanque diagram.
#
#
class ConverterPosition < ActiveRecord::Base

  DEFAULT_Y_BY_SECTOR = {
    :households   =>  100,
    :industry     => 9000,
    :transport    => 3500,
    :agriculture  => 5300,
    :energy       => 3000,
    :other        => 8300,
    :environment  => 100,
    :buildings    => 6100,
    :neighbor     =>  100
  }.with_indifferent_access

  STROKE_COLORS_BY_SECTOR = {
    :households   => '#E69567',
    :industry     => '#CCCCCC',
    :transport    => '#FFD700',
    :agriculture  => '#B3CF7B',
    :energy       => '#ADD8E6',
    :other        => '#FF6666',
    :environment  => '#32CD32',
    :buildings    => '#FF6666',
    :neighbor     => '#87CEEB'
  }.with_indifferent_access

  #belongs_to :converter
  belongs_to :blueprint_layout

  validates_presence_of :converter_id, :on => :create, :message => "can't be blank"

  scope :not_hidden, where(:hidden => false)

  def self.default_position_for(converter)
    position = new
    position.tap{|p| p.converter = converter }
  end

  def fill_color(converter)
    if converter && converter.sector_key
      STROKE_COLORS_BY_SECTOR[converter.sector_key.to_sym]
    else
      '#eee'
    end
  end

  def stroke_color(converter)
    (converter && EnergyBalanceGroup.find_by_name(converter.energy_balance_group).andand.graphviz_color) || '#999'
  end

  def x_or_default(converter)
    self.x || EnergyBalanceGroup.find_by_name(converter.energy_balance_group).andand.graphviz_default_x || 100
  end

  def y_or_default(converter)
    self.y || DEFAULT_Y_BY_SECTOR[converter.sector_key.to_s.to_sym] || 100
  end
end
