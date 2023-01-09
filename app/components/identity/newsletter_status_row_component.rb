# frozen_string_literal: true

module Identity
  class NewsletterStatusRowComponent < ApplicationComponent
    include ButtonHelper

    def initialize(subscribed:)
      @subscribed = subscribed
    end
  end
end
