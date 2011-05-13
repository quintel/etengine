# == Schema Information
#
# Table name: links
#
#  id           :integer(4)      not null, primary key
#  blueprint_id :integer(4)
#  parent_id    :integer(4)
#  child_id     :integer(4)
#  carrier_id   :integer(4)
#  link_type    :integer(4)
#

#
#
# parent_id is to left
# child_id is to right
#
class Link < ActiveRecord::Base
  belongs_to :blueprint

  LINK_TYPES = { 1 => :share,
                 2 => :dependent,
                 3 => :flexible,
                 4 => :constant,
                 5 => :inversed_flexible  }

  belongs_to :carrier

  belongs_to :child, :class_name => 'Converter'
  belongs_to :blueprint_parent, :class_name => 'Converter'

  validates_presence_of :parent_id
  validates_presence_of :child_id

  # TODO sebi please help with this validation
  # validates_uniqueness_of :child_id, :scope => [:graph_id, :parent_id, :carrier_id]

  validates_presence_of :carrier_id

  validates_presence_of :link_type
  validates_inclusion_of :link_type, :in => LINK_TYPES.keys

  # validates_numericality_of :share, :if => Proc.new{|l| l.link_type == 1}

  module Scopes
    def blueprint(blueprint)
      where({:blueprint_id => blueprint.is_a?(Blueprint) ? blueprint.id : blueprint}) 
    end
  end
  extend Scopes

  def link_type_key
    LINK_TYPES[link_type]
  end

  LINK_STYLES = {
    'constant'  => '-',
    'share'     => '-',
    'flexible'  => '. ',
    'dependent' => '--..'
  }

  ##
  # @experimental 2010-08-27 seb experimental for sanquee
  def link_style
    LINK_STYLES[link_type_key.to_s]
  end

  def output_converter
    Converter.find(id_of_output_converter)
  end

  def input_converter
    Converter.find(id_of_input_converter)
  end

  ##
  # converter to the right
  #
  def id_of_input_converter
    child_id
  end

  ##
  # converter to the left
  #
  def id_of_output_converter
    parent_id
  end
end


