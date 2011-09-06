# == Schema Information
#
# Table name: converters
#
#  id                   :integer(4)      not null, primary key
#  converter_id         :integer(4)
#  key                  :string(255)
#  name                 :string(255)
#  use_id               :integer(4)
#  sector_id            :integer(4)
#  created_at           :datetime
#  updated_at           :datetime
#  energy_balance_group :string(255)
#

##
# id = excel_id
#
class Converter < ActiveRecord::Base
  has_paper_trail

  #  belongs_to :blueprint
  has_and_belongs_to_many :blueprints
  has_and_belongs_to_many :groups

  has_many :links, :foreign_key => 'child_id'
  has_many :input_links,  :class_name => 'Link', :foreign_key => 'parent_id'
  has_many :output_links, :class_name => 'Link', :foreign_key => 'child_id'
  has_many :slots

  has_one :converter_position

  scope :in_group, lambda{|*gid| includes(:groups).where(["groups.id IN (?)", gid])}
  # we hook up converters with slots in Blueprint. So the following association not
  # really needed.
  # has_many :blueprint_slots

  # We don't check for excel_id, because we assign it usign assign_excel_id_to_id
  # validates_presence_of :excel_id, :on => :create, :message => "can't be blank"

  after_save :assign_converter_id_to_id

  ##
  # makes sure that id is always equals converter_id. As the auto increment can screw things up.
  #
  def assign_converter_id_to_id
    Converter.update_all("id = converter_id", "id = #{self.id}")
    self.id = self.converter_id
  end

  def to_label
    "##{id} #{full_key}"
  end

  def full_key
    Qernel::Converter.full_key(key.andand.downcase, sector_id, use_id)
  end

  def use_key
    Qernel::Converter::USES[use_id]
  end

  def sector_key
    Qernel::Converter::SECTORS[sector_id]
  end

  ##
  # @experimental 2010-08-27 seb experimental for sanquee
  def chart_x
    if converter_position.andand.x
      return converter_position.andand.x
    else
      return 7100 if groups.map(&:key).include?('energy_import_export')
      return 5200 if groups.map(&:key).include?('sustainable_production')
      return 7200 if groups.map(&:key).include?('mining_and_extraction')
      return 3000 if groups.map(&:key).include?('non_energetic_use')
      return 7000 if groups.map(&:key).include?('primary_energy_demand')
      return  100 if groups.map(&:key).include?('useful_demand')
      return 4000 if groups.map(&:key).include?('final_demand_cbs')
      return 6000 if groups.map(&:key).include?('electricity_production')
      return 5000 if groups.map(&:key).include?('decentral_production')
      return 5500 if groups.map(&:key).include?('heat_production')
      return  1000
    end
  end

  ##
  # @experimental 2010-08-27 seb experimental for sanquee
  def chart_y
    if converter_position.andand.y
      return converter_position.andand.y
    else
      (sector_id || 0) * 900
    end
  end

  ##
  #
  # Build a Qernel::Converter from a blueprint
  #
  def to_qernel
    unless @qernel_obj
      @qernel_obj = Qernel::Converter.new(id, key, use_id, sector_id, self.groups.map(&:to_qernel).uniq)
    end
    @qernel_obj
  end
end
