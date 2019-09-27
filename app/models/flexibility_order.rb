# frozen_string_literal: true

class FlexibilityOrder < ApplicationRecord
  GROUPS = %w[
    household_batteries
    mv_batteries
    electric_vehicle
    opac
    pumped_storage
    power_to_gas
    power_to_gas_industry
    power_to_heat
    power_to_heat_industry
    power_to_kerosene
    export
  ].map(&:freeze).freeze

  serialize :order, Array

  belongs_to :scenario

  validates :scenario_id, uniqueness: true

  def self.default_order
    GROUPS
  end
end
