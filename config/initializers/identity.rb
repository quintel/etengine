# frozen_string_literal: true


if !ENV['DOCKER_BUILD'] && (
    Settings.identity.issuer.blank? ||
    Settings.identity.client_id.blank? ||
    Settings.identity.client_secret.blank?)
  abort <<~MESSAGE
    ┌─────────────────────────────────────────────────────────────────────────┐
    │           !!!️  NO IDENTITY / AUTHENTICATION CONFIG FOUND !!!️            │
    ├─────────────────────────────────────────────────────────────────────────┤
    │ You're missing the client_id and client_secret used to authenticate.    │
    │ Please add these to your config/settings.local.yml file.                │
    │                                                                         │
    │ 1. Visit the MyETM you wish to connect to. If you're running            │
    │    MyETM locally, start it with: bin/dev -p3002.                        │
    │                                                                         │
    │ 2. Sign in to your MyETM account. If MyETM is running locally,          │
    │    sign in at http://localhost:3002.                                    │
    │                                                                         │
    │ 3. Create a new Engine, Model or Collections application.               │
    │                                                                         │
    │ 4. Copy the generated config to ETEngine (config/settings.local.yml).   │
    └─────────────────────────────────────────────────────────────────────────┘
  MESSAGE
end

Identity.configure do |config|
  config.issuer = Settings.identity.issuer
  config.client_uri = Settings.identity.client_uri
  config.client_id = Settings.identity.client_id
  config.client_secret = Settings.identity.client_secret
  config.scope = 'openid profile email roles scenarios:read scenarios:write scenarios:delete'
  config.validate_config = ENV['DOCKER_BUILD'] != 'true'
  # No resource app configured - ETModel is no longer a resource
  config.resource_uri = ''
end

if Rails.env.development?
  # In development, ETEngine often runs as only a single process. Pre-fetch the JWKS keys from the
  # engine so that the first request to the API does not deadlock.
  begin
    Identity::TokenDecoder.jwk_set
  rescue StandardError => e
    warn("Couldn't pre-fetch MyETM public key: #{e.message}")
  end
end
