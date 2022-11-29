# frozen_string_literal: true

# Provides a helper method for creating CSS classes for buttons and button-like elements.
module ButtonHelper
  BASE_CLASSES = %w[
    cursor-pointer
    font-medium
    inline-flex
    items-center
    rounded
    transition
    disabled:pointer-events-none
    disabled:opacity-50
    focus-visible:ring-2
    focus-visible:outline-none
  ].freeze

  COLORS = {
    default: %w[
      text-gray-700
      hover:text-gray-700
      active:text-gray-800

      bg-gray-200
      hover:bg-gray-300
      active:bg-gray-350

      focus-visible:ring-midnight-600
    ],

    primary: %w[
      text-midnight-50
      hover:text-midnight-50
      active:text-midnight-50

      bg-midnight-600
      hover:bg-midnight-700
      active:bg-midnight-800

      focus-visible:ring-midnight-800
    ],

    success: %w[
      text-emerald-50
      hover:text-emerald-50
      active:text-emerald-50

      bg-emerald-600
      hover:bg-emerald-700
      active:bg-emerald-800

      focus-visible:ring-emerald-800
    ],

    link: %w[
      text-midnight-600
      hover:text-gray-700
      active:text-gray-700

      bg-transparent
      hover:bg-gray-100
      active:bg-gray-200

      focus-visible:ring-midnight-500
    ]
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
