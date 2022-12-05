class Identity::TokenMailer < ApplicationMailer
  helper Identity::TokenMailerHelper

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.identity.token_mailer.created_token.subject
  #
  def created_token(token)
    @token = token
    @access_token = token.oauth_access_token

    mail(to: @token.user.email, from: Settings.mailer.from)
  end

  # Message sent to a user when one of their tokens is about to expire.
  def expiring_token(token)
    @token = token
    @access_token = token.oauth_access_token

    mail(to: @token.user.email, from: Settings.mailer.from)
  end
end
