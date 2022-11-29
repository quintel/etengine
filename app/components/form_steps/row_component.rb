# frozen_string_literal: true

class FormSteps::RowComponent < ViewComponent::Base
  renders_one :icon
  renders_one :after_hint

  def initialize(title:, label_for:, hint: nil)
    @title = title
    @label_for = label_for
    @hint = hint
  end
end
