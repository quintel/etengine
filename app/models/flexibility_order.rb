class FlexibilityOrder < ActiveRecord::Base
  serialize :order, Array

  def self.default_order
    %w(power_to_power_in_batteries power_to_power_in_ev power_to_gas
       power_to_heat export)
  end
end
