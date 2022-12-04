# frozen_string_literal: true

class FieldErrorsComponent < ApplicationComponent
  def initialize(record:, attribute:)
    @messages = record.errors.full_messages_for(attribute)
  end
end
