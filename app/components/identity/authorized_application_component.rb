# frozen_string_literal: true

module Identity
  class AuthorizedApplicationComponent < ApplicationComponent
    include Turbo::FramesHelper
    include ButtonHelper

    option :application
  end
end
