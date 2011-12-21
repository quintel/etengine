# == Schema Information
#
# Table name: converters
#
#  id                      :integer(4)      not null, primary key
#  converter_id            :integer(4)
#  key                     :string(255)
#  name                    :string(255)
#  use_id                  :integer(4)
#  sector_id               :integer(4)
#  created_at              :datetime
#  updated_at              :datetime
#  energy_balance_group_id :integer(4)
#

class Converter < ActiveRecord::Base
  has_paper_trail

  has_and_belongs_to_many :blueprints
  has_and_belongs_to_many :groups
  belongs_to :energy_balance_group

  # Remember that most of these associations make sense only in the context of
  # a blueprint
  has_many :links, :foreign_key => 'child_id'
  has_many :input_links,  :class_name => 'Link', :foreign_key => 'parent_id'
  has_many :output_links, :class_name => 'Link', :foreign_key => 'child_id'
  has_many :slots
  has_one :converter_position

  scope :in_group, lambda{|*gid| includes(:groups).where(["groups.id IN (?)", gid]) unless gid.empty?}
  scope :by_name, lambda{|q| where('`converters`.`key` LIKE ?', "%#{q}%")}

  after_save :assign_converter_id_to_id

  # makes sure that id is always equals converter_id, matching the ids of the
  # excel file used to import the graph. The auto increment can screw things up.
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
  #
  # Build a Qernel::Converter from a blueprint
  #
  def to_qernel
    unless @qernel_obj
      group_keys = self.groups.map(&:to_qernel).uniq
      eb_group_key = energy_balance_group.andand.name.andand.to_sym || :undefined
      @qernel_obj = Qernel::Converter.new(id, key, use_id, sector_id, group_keys, eb_group_key)
    end
    @qernel_obj
  end
  
  # Hash that maps converter fullkeys to ids. Used to lookup a converter by
  # full_key, which is made up of the concatenation of different strings
  def self.full_keys
    Rails.cache.fetch 'converter_full_keys' do
      out = {}
      all.each {|c| out[c.full_key] = c.id}
      out
    end
  end
end
