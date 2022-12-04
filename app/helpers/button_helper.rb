# frozen_string_literal: true

# Provides a helper method for creating CSS classes for buttons and button-like elements.
module ButtonHelper
  BASE_CLASSES = %w[button].freeze

  COLORS = {
    gray: %w[button-gray],
    primary: %w[button-primary],
    success: %w[button-success],
    warning: %w[button-warning],
    link: %w[button-link],
    default: %w[button-default],
    default_colored: %w[button-colored]
  }.freeze

  SIZES = {
    sm: ['px-2 py-1'],
    base: ['px-3 py-1.5'],
    lg: ['px-4 py-2']
  }.freeze

  NEGATE_PADDING = {
    sm: { x: '-mx-2', y: '-my-1' },
    base: { x: '-mx-3', y: '-my-1.5' },
    lg: { x: '-mx-4', y: '-my-2' }
  }.freeze

  def button_classes(additional = nil, color: :default, size: :base, negate_padding: false)
    negative_margin = button_negated_padding_classes(size, negate_padding)

    classes = (BASE_CLASSES + COLORS.fetch(color) + SIZES.fetch(size)).join(' ')
    classes += " #{negative_margin}" if negative_margin
    classes += " #{additional}" if additional

    classes
  end

  private

  def button_negated_padding_classes(size, direction)
    case direction
    when true
      "#{NEGATE_PADDING[size][:x]} #{NEGATE_PADDING[size][:y]}"
    when :x
      NEGATE_PADDING[size][:x]
    when :y
      NEGATE_PADDING[size][:y]
    end
  end
end
