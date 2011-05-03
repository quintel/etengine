##
# This class stores x,y values for the new online sanque diagram.
#
#
class ConverterPosition < ActiveRecord::Base
  belongs_to :converter
  belongs_to :blueprint_layout

  validates_presence_of :converter_id, :on => :create, :message => "can't be blank"

  before_create :assign_colors

  def assign_colors
    return unless converter
    STROKE_COLORS.each do |key, color|
      if converter.groups.map(&:key).include?(key.to_s)
        stroke_color = color
      end
    end
    self[:stroke_color] ||= STROKE_COLORS[:undefined]
    self[:fill_color] = FILL_COLORS[converter.sector_key.to_sym] if converter.sector_key
  end


  FILL_COLORS_BALANCE_GROUP = {
    
  }

   FILL_COLORS = {
    :households   => '#fcf',
    :industry     => '#ccc',
    :transport    => '#ffc',
    :agriculture  => '#cfc',
    :energy       => '#ffc',
    :other        => '#fff',
    :environment  => '#fcc',
    :buildings    => '#dee',
    :neighbor     => '#ccc'  
  }.with_indifferent_access

  STROKE_COLORS = {
    :primary_energy_demand => '#99f',
    :final_demand_cbs => '#9f9',
    :useful_demand => '#f99',
    :undefined => '#333'
  }.with_indifferent_access

end


# == Schema Information
#
# Table name: converter_positions
#
#  id           :integer(4)      not null, primary key
#  converter_id :integer(4)
#  x            :integer(4)
#  y            :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#

