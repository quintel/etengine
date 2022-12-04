# frozen_string_literal: true

module Identity
  class RowComponent < ViewComponent::Base
    renders_one :title_contents

    def initialize(title: nil)
      @title = title
    end
  end
end
