# frozen_string_literal: true

Sentry.init do |config|
  # Set release version
  config.release = '2024.09.1'

  config.dsn = ENV.fetch('SENTRY_DSN', nil)
  config.enabled_environments = %w[production staging]

  # This sends information such as the query params and request body, and IP address. Sentry is
  # configured to filter out and not store the IP address since we only want the params and body.
  config.send_default_pii = true

  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for tracing.
  config.traces_sample_rate = ENV.fetch('SENTRY_TRACES', 0.1).to_f

  # Set profiles_sample_rate to profile 100%
  # of sampled transactions.
  config.profiles_sample_rate = ENV.fetch('SENTRY_PROFILES', 0.1).to_f
end
