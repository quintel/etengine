# frozen_string_literal: true

class FlexibilityOrder < ApplicationRecord
  serialize :order, Array

  belongs_to :scenario

  validates :scenario_id, presence: true, uniqueness: true

  validates_with Atlas::FlexibilityOrderValidator,
    attribute: :order,
    in: -> { FlexibilityOrder.default_order }

  def as_json(*)
    { order: useable_order }
  end

  # Public: The flexibility order with any invalid options removed, and any
  # missing options appended with the default sorting.
  def useable_order
    defaults = self.class.default_order
    intersection = order & defaults

    if intersection.length != defaults.length
      # Merge specified options with those missing.
      intersection.concat(defaults - intersection)
    end

    intersection
  end

  def self.default
    new(order: default_order)
  end

  def self.default_order
    Etsource::Config.flexibility_order
  end
end
