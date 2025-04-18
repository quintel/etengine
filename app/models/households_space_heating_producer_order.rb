# frozen_string_literal: true

# Allows the user to choose a custom sorting of households space heating producers.
class HouseholdsSpaceHeatingProducerOrder < ApplicationRecord
  include UserSortable

  validates :scenario_id, presence: true, uniqueness: true
  serialize :order, type: Array, coder: MessagePack

  def self.default_order
    Etsource::Config.fever_order(:space_heating, :producer).map(&:to_s)
  end

  # Which attribute to use to specify the default order. Here nil
  def self.specify_default; end

  def graph_key
    :households_space_heating_producer_order
  end
end
