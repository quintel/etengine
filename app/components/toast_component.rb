# frozen_string_literal: true

class ToastComponent < ApplicationComponent
  def initialize(message:, type: :notice)
    @type = type

    if message.is_a?(Hash)
      @title = no_break_on_hyphen(message[:title] || message['title'])
      @message = no_break_on_hyphen(message[:message] || message['message'])
    else
      @message = no_break_on_hyphen(message)
    end
  end

  private

  # Replaces any hyphen in the message with a character taht won't trigger line breaks.
  def no_break_on_hyphen(string)
    string.tr('-', '‑')
  end
end
