# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def password_reset_instructions
    user = User.first
    user.reset_token = User.new_token
    UserMailer.password_reset_instructions(user)
  end
end
