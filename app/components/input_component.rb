# frozen_string_literal: true

class InputComponent < ApplicationComponent
  def initialize(form:, name:, **attributes)
    @form = form
    @name = name
    @attributes = attributes
  end
end
