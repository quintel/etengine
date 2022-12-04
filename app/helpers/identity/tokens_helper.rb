# frozen_string_literal: true

module Identity
  module TokensHelper
    def token_expiration_options(value)
      options_for_select(
        [
          token_expiration_option('n_days', 7),
          token_expiration_option('n_days', 30),
          token_expiration_option('n_days', 60),
          token_expiration_option('n_days', 90),
          token_expiration_option('one_year', 365),
          [
            t('identity.tokens.expiration_options.never'),
            'never',
            { 'data-message' => t('identity.tokens.expiration_options.never_message') }
          ]
        ],
        value
      )
    end

    def token_expiration_option(message_key, days)
      [
        t(message_key, scope: 'identity.tokens.expiration_options', n: days),
        days,
        {
          'data-message' => t(
            'identity.tokens.expiration_options.expires_at_message',
            date: l(days.days.from_now, format: :date)
          )
        }
      ]
    end
  end
end
