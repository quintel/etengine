# frozen_string_literal: true

module Identity
  class ProfileRowComponent < ViewComponent::Base
    renders_one :message
    renders_one :button

    def initialize(title:, compact: false)
      @title = title
      @compact = compact
    end
  end
end
