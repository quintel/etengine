# frozen_string_literal: true

# Allows the user to choose a custom sorting of dispatchable heat producers in
# the heat network. HeatNetworks default to Medium Temperature (mt).
class HeatNetworkOrder < ApplicationRecord
  include UserSortable

  validates :temperature, presence: true, inclusion: {
    in: %w[ht mt lt],
    message: "%{value} is not a valid temperature level"
  }

  validates :temperature, uniqueness: {
    scope: :scenario_id,
    case_sensitive: false,
    message: 'already exists for this scenario'
  }

  def self.default_order(temperature = :mt)
    Etsource::Config.public_send("heat_network_order_#{temperature}")
  end

  def graph_key
    :"heat_network_order_#{temperature}"
  end
end
