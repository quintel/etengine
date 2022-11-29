# frozen_string_literal: true

class PasswordFieldComponent < InputComponent
  include CssClasses

  DEFAULT_CLASSES = %w[!pr-12].freeze

  def initialize(form:, name:, **attributes)
    super
    @attributes = merge_attributes(attributes)
  end
end
