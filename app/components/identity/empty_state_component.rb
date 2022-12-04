# frozen_string_literal: true

module Identity
  class EmptyStateComponent < ApplicationComponent
    renders_one :buttons
    option :title
  end
end
