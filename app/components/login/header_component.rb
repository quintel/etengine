# frozen_string_literal: true

module Login
  class HeaderComponent < ViewComponent::Base
    def initialize(title:, subtext: nil)
      @title = title
      @subtext = subtext
    end
  end
end
