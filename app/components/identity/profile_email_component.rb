# frozen_string_literal: true

module Identity
  class ProfileEmailComponent < ViewComponent::Base
    include ButtonHelper

    def initialize(title:, email:, confirmed:, show_change_button: true)
      @title = title
      @email = email
      @confirmed = confirmed
      @show_change_button = show_change_button
    end
  end
end
