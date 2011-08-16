# == Schema Information
#
# Table name: carriers
#
#  id            :integer(4)      not null, primary key
#  carrier_id    :integer(4)
#  key           :string(255)
#  name          :string(255)
#  infinite      :boolean(1)
#  created_at    :datetime
#  updated_at    :datetime
#  carrier_color :string(255)
#

class Carrier < ActiveRecord::Base
  belongs_to :blueprint

  # If carrier_id is undefined assign_carrier_id_to_id will
  # assign nil to the primary key id.
  validates_presence_of :carrier_id

  after_save :assign_carrier_id_to_id

  def self.keys
    @keys ||= all.map(&:key)
  end

  ##
  # makes sure that id is always equals excel_id. As the auto increment can screw things up.
  # DEBT ugly
  def assign_carrier_id_to_id
    Carrier.update_all("id = carrier_id", "id = #{self.id}")
    self.id = self.carrier_id
  end

  ##
  #
  # Build a Qernel::Carrier from a blueprint
  #
  def to_qernel
    @qernel ||= Qernel::Carrier.new(id, key, (infinite ? 1.0 : 0.0))
  end
end
