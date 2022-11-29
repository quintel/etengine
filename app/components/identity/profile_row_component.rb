# frozen_string_literal: true

module Identity
  class ProfileRowComponent < ViewComponent::Base
    def initialize(title:)
      @title = title
    end
  end
end
