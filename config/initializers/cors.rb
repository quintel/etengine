# frozen_string_literal: true

# Same-registrable-domain ETM apps (ETModel, Collections) call the API from the browser carrying the
# shared session cookie, so they need credentialed CORS. The CORS spec forbids credentials with a
# wildcard origin, hence a specific-origin block, matched first. Defaults cover every prod and dev
# ETM subdomain.
SESSION_CORS_ORIGINS =
  ENV['CORS_SESSION_ORIGINS'].to_s.split(',').map(&:strip).presence || [
    %r{\Ahttps?://([a-z0-9-]+\.)*energytransitionmodel\.com(:\d+)?\z},
    %r{\Ahttps?://([a-z0-9-]+\.)*etm\.test(:\d+)?\z}
  ]

Rails.application.config.middleware.insert_before(0, Rack::Cors) do
  allow do
    origins(*SESSION_CORS_ORIGINS)
    resource '/api/*',
      headers: :any,
      credentials: true,
      methods: %i[get post put patch delete options head]
  end

  # Token/PAT API clients authenticate with a bearer header (no cookies), so any origin is allowed.
  allow do
    origins '*'
    resource '/api/*',
      headers: :any,
      methods: %i[get post put patch delete options head]
  end
end
