# frozen_string_literal: true

class FlexibilityOrder < ApplicationRecord
  serialize :order, Array

  belongs_to :scenario

  validates :scenario_id, uniqueness: true

  validates_with Atlas::FlexibilityOrderValidator,
    attribute: :order,
    in: -> { FlexibilityOrder.default_order }

  def as_json(*)
    { order: order }
  end

  def self.default
    new(order: default_order)
  end

  def self.default_order
    Etsource::Config.flexibility_order
  end
end
