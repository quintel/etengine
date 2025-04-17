# frozen_string_literal: true

# Allows the user to choose a custom sorting of hydrogen flex demand.
class HydrogenDemandOrder < ApplicationRecord
  include UserSortable

  validates :scenario_id, presence: true, uniqueness: true
  serialize :order, type: Array, coder: MessagePack

  def self.default_order
    Etsource::Config.hydrogen_demand_order
  end

  # Which attribute to use to specify the default order. Here nil
  def self.specify_default; end

  def graph_key
    :hydrogen_demand_order
  end
end
