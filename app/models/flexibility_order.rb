class FlexibilityOrder < ActiveRecord::Base
  GROUPS = %w(
    power_to_power
    electric_vehicle
    power_to_gas
    power_to_heat
    export
  ).map(&:freeze).freeze

  serialize :order, Array

  belongs_to :scenario

  validates :scenario_id, uniqueness: true

  def self.default_order
    GROUPS
  end
end
