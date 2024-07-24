class UserMailer < ActionMailer::Base
  default from: "mailserver@quintel.com"

  include Devise::Controllers::UrlHelpers

  def password_reset_instructions(user)
    @user = user
    @token = @user.reset_token

    I18n.with_locale do
      mail(
        to: user.email,
        subject: I18n.t('user.forgot_password.mail.subject'),
        template_path: 'devise/mailer',
        template_name: 'reset_password_instructions'
      )
    end
  end
end
