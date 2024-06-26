# frozen_string_literal: true

# Allows the user to choose a custom sorting of hydrogen supply.
class HydrogenSupplyOrder < ApplicationRecord
  include UserSortable

  validates :scenario_id, presence: true, uniqueness: true

  def self.default_order
    Etsource::Config.hydrogen_supply_order
  end

  # Which attribute to use to specify the default order. Here nil
  def self.specify_default; end

  def graph_key
    :hydrogen_supply_order
  end
end
