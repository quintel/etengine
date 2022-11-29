# frozen_string_literal: true

class FieldErrorsComponent < ViewComponent::Base
  def initialize(record:, attribute:)
    @messages = record.errors.full_messages_for(attribute)
  end
end
