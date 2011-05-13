# == Schema Information
#
# Table name: slots
#
#  id           :integer(4)      not null, primary key
#  blueprint_id :integer(4)
#  converter_id :integer(4)
#  carrier_id   :integer(4)
#  direction    :integer(4)
#

class Slot < ActiveRecord::Base

  INPUT_DIRECTION = 0
  OUTPUT_DIRECTION = 1

  module Scopes
    def blueprint(blueprint)
      where({:blueprint_id => blueprint.is_a?(Blueprint) ? blueprint.id : blueprint}) 
    end

    def input
      where("direction = #{INPUT_DIRECTION}")
    end

    def output
      where("direction = #{OUTPUT_DIRECTION}")
    end
  end
  extend Scopes

  belongs_to :blueprint
  belongs_to :carrier

  def input?
    direction == INPUT_DIRECTION
  end

  def output?
    direction == OUTPUT_DIRECTION
  end

  def links
    links = Link.blueprint(blueprint).
      where({:carrier_id => carrier_id})
    if input?
      links = links.where(["parent_id = ?", converter_id])
    else
      links = links.where(["child_id = ?", converter_id])
    end
  end
end


