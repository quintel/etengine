# frozen_string_literal: true

class InputComponent < ViewComponent::Base
  def initialize(form:, name:, **attributes)
    @form = form
    @name = name
    @attributes = attributes
  end
end
