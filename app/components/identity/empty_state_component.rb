# frozen_string_literal: true

module Identity
  class EmptyStateComponent < ViewComponent::Base
    renders_one :buttons

    def initialize(title:)
      super

      @title = title
    end
  end
end
