# frozen_string_literal: true

# Describes a collection of strings which may be sorted by the user according to
# their preferences in order to customise calculation order in Causality
# modules.
module UserSortable
  extend ActiveSupport::Concern

  included do
    serialize :order, Array
    belongs_to :scenario
    validates :scenario_id, presence: true, uniqueness: true

    validates_with Atlas::UserSortableValidator,
      attribute: :order,
      in: -> { default_order }
  end

  class_methods do
    def default(attrs = {})
      new(attrs.merge(order: default_order))
    end
  end

  def as_json(*)
    { order: useable_order }
  end

  # Public: The flexibility order with any invalid options removed, and any
  # missing options appended with the default sorting.
  def useable_order
    defaults = self.class.default_order
    intersection = order & defaults

    if intersection.length != defaults.length
      # Merge specified options with those missing.
      intersection.concat(defaults - intersection)
    end

    intersection
  end

  def default?
    order.empty? || useable_order == self.class.default_order
  end

  def graph_key
    raise NotImplementedError
  end
end
