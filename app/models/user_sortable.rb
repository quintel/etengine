# frozen_string_literal: true

# Describes a collection of strings which may be sorted by the user according to
# their preferences in order to customise calculation order in Causality
# modules.
module UserSortable
  extend ActiveSupport::Concern

  included do
    serialize :order, type: Array, coder: MessagePack
    belongs_to :scenario

    validates_with Atlas::UserSortableValidator,
      attribute: :order,
      with: -> { specify_default },
      in: ->(w) { w.nil? ? default_order : default_order(w) }
  end

  class_methods do
    def default(attrs = {})
      use_order = specify_default.nil? ? default_order : default_order(attrs[specify_default])

      new(attrs.merge(order: use_order))
    end
  end

  def as_json(*)
    { order: useable_order }
  end

  # Public: The flexibility order with any invalid options removed, and any
  # missing options appended with the default sorting.
  def useable_order
    defaults = specified_defaults
    intersection = order & defaults

    if intersection.length != defaults.length
      # Merge specified options with those missing.
      intersection.concat(defaults - intersection)
    end

    intersection
  end

  def default?
    order.empty? || useable_order == specified_defaults
  end

  def graph_key
    raise NotImplementedError
  end

  # We need this extra method in order to use the different temperature levels for heat networks
  def specified_defaults
    if self.class.specify_default.nil?
      self.class.default_order
    else
      self.class.default_order(public_send(self.class.specify_default))
    end
  end
end
