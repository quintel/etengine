# frozen_string_literal: true

# Allows the user to choose a custom sorting of dispatchable heat producers in
# the heat network.
class HeatNetworkOrder < ApplicationRecord
  include UserSortable

  def self.default_order
    Etsource::Config.heat_network_order
  end

  def graph_key
    :heat_network_order
  end
end
