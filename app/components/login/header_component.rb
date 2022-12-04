# frozen_string_literal: true

module Login
  class HeaderComponent < ApplicationComponent
    option :title
    option :subtext, optional: true
  end
end
