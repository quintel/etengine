# frozen_string_literal: true

module Identity
  class RowComponent < ApplicationComponent
    renders_one :title_contents
    option :title, optional: true
  end
end
