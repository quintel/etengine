# frozen_string_literal: true

class Identity::PageHeaderComponent < ApplicationComponent
  renders_one :actions

  option :title
  option :message
end
