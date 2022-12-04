# frozen_string_literal: true

module Identity
  class ProfileRowComponent < ApplicationComponent
    renders_one :message
    renders_one :button

    option :title
    option :compact, default: proc { false }
  end
end
