# frozen_string_literal: true

module SelectLocale
  class ItemComponent < ApplicationComponent
    option :href
    option :selected, default: proc { false }
  end
end
