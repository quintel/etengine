# frozen_string_literal: true

module Identity
  class ProfileEmailComponent < ApplicationComponent
    include ButtonHelper

    option :title
    option :email
    option :confirmed
    option :show_change_button, default: proc { true }
  end
end
