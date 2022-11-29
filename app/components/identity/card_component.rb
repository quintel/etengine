# frozen_string_literal: true

module Identity
  class CardComponent < ViewComponent::Base
    renders_one :header_right

    def initialize(title:, icon:, id: nil)
      super

      @title = title
      @icon = icon
      @id = id
    end
  end
end
