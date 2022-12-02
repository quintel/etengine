# frozen_string_literal: true

module SelectLocale
  class ItemComponent < ViewComponent::Base
    def initialize(href:, selected: false)
      @href = href
      @selected = selected
    end
  end
end
