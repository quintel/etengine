# frozen_string_literal: true

module Login
  class ActionButtonComponent < ApplicationComponent
    include ButtonHelper

    BASE_CLASSES = 'text-base flex items-center justify-center group'

    def initialize(form:, color: :default, size: :base, **attributes)
      @form = form

      additional_classes = [BASE_CLASSES, attributes.delete(:class)].compact.join(' ')

      @attributes = attributes.merge(
        class: button_classes(additional_classes, color:, size:),
        type: attributes[:type] || 'submit'
      )
    end
  end
end
