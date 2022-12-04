# frozen_string_literal: true

module Identity
  class CardComponent < ApplicationComponent
    renders_one :header_right

    option :title
    option :icon
    option :id, optional: true
  end
end
