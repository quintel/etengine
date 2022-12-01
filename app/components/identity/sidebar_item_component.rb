# frozen_string_literal: true

class Identity::SidebarItemComponent < ViewComponent::Base
  def initialize(path:, title:, explanation:, active: false)
    @path = path
    @title = title
    @explanation = explanation
    @active = active
  end

  def css_classes
    if @active
      'border-midnight-600 text-midnight-700 hover:text-midnight-700 hover:bg-gray-50'
    else
      'border-gray-200 text-gray-700 hover:border-gray-350 hover:text-gray-700 hover:bg-gray-50'
    end
  end
end
