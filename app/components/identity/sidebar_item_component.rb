# frozen_string_literal: true

class Identity::SidebarItemComponent < ApplicationComponent
  option :path
  option :title
  option :explanation
  option :active, default: proc { false }

  def css_classes
    if @active
      'border-midnight-600 text-midnight-700 hover:text-midnight-700 hover:bg-gray-50'
    else
      'border-gray-200 text-gray-700 hover:border-gray-350 hover:text-gray-700 hover:bg-gray-50'
    end
  end
end
