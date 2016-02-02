class FlexibilityOrder < ActiveRecord::Base
  GROUPS = %w(
    power_to_power
    electric_vehicle
    power_to_gas
    power_to_heat
    export
  ).map(&:freeze).freeze

  serialize :order, Array

  def self.default_order
    GROUPS
  end
end
