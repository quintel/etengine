# frozen_string_literal: true

module CssClasses
  private

  def merge_attributes(attributes)
    attributes.merge(class: [attributes[:class], *self.class::DEFAULT_CLASSES].compact.join(' '))
  end
end
