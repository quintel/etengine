##
#
# @deprecated
#
class Group < ActiveRecord::Base
  has_and_belongs_to_many :converters

  validates_presence_of :group_id
  validates_presence_of :title

  after_save :assign_group_id_to_id

  def self.keys
    @keys ||= all.map(&:key)
  end

  ##
  # makes sure that id is always equals excel_id. As the auto increment can screw things up.
  #
  def assign_group_id_to_id
    Group.update_all("id = group_id", "id = #{self.id}")
    self.id = self.group_id
  end

  def to_qernel
    @qernel ||= Qernel::Group.new(id, key)
  end
end


# == Schema Information
#
# Table name: groups
#
#  id                 :integer(4)      not null, primary key
#  title              :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  key                :string(255)
#  shortcut           :string(255)
#  group_id :integer(4)
#

