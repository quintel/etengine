# frozen_string_literal: true

module Login
  class ButtonComponent < ActionButtonComponent
    def initialize(form:)
      super(form:, type: :submit, color: :primary, size: :lg, class: 'w-full !py-3')
    end
  end
end
