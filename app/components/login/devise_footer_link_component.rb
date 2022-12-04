# frozen_string_literal: true

module Login
  class DeviseFooterLinkComponent < ApplicationComponent
    include CssClasses

    DEFAULT_CLASSES = %w[
      font-medium
      inline-block
      px-2 py-1
      rounded
      text-gray-500 text-sm
      transition

      active:bg-gray-300 active:text-gray-700
      hover:bg-gray-200 hover:text-gray-700
    ].freeze

    def initialize(path:, **attributes)
      @path = path
      @attributes = merge_attributes(attributes)
    end
  end
end
