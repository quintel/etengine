# frozen_string_literal: true

class FlexibilityOrder < ApplicationRecord
  serialize :order, Array

  belongs_to :scenario

  validates :scenario_id, uniqueness: true

  def self.default_order
    Etsource::Config.flexibility_order
  end
end
