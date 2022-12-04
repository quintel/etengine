# frozen_string_literal: true

class Identity::PageHeaderComponent < ViewComponent::Base
  renders_one :actions

  def initialize(title:, message:)
    @title = title
    @message = message
  end
end
