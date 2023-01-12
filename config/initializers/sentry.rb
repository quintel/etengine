# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN', nil)
  config.enabled_environments = %w[production staging]

  # This sends information such as the query params and request body, and IP address. Sentry is
  # configured to filter out and not store the IP address since we only want the params and body.
  config.send_default_pii = true
end
