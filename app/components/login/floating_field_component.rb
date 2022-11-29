# frozen_string_literal: true

module Login
  class FloatingFieldComponent < ViewComponent::Base
    renders_one :field

    def initialize(name:, title:, form:, type: nil, **field_attributes)
      @form = form
      @name = name
      @title = title
      @type = type
      @field_attributes = field_attributes
    end
  end
end
