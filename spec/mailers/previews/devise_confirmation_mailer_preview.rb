# frozen_string_literal: true

class DeviseConfirmationMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    user = User.first || User.new(email: 'test@example.com', confirmation_token: 'fake_token')
    Devise::Mailer.confirmation_instructions(user, user.confirmation_token)
  end
end
