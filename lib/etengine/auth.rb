# frozen_string_literal: true

module ETEngine
  # Contains useful methods for authentication.
  module Auth
    module_function

    # Generates a new signing key for use in development and saves it to the tmp directory. If a key
    # already exists there, it will be read.
    def signing_key_content
      return ENV['OPENID_SIGNING_KEY'] if ENV['OPENID_SIGNING_KEY'].present?

      key_path = Rails.root.join('tmp/openid.key')

      return key_path.read if key_path.exist?

      unless Rails.env.test? || Rails.env.development? || ENV['CI']
        raise 'No signing key is present. Please set the OPENID_SIGNING_KEY environment ' \
              'variable or add the key to tmp/openid.key.'
      end

      key = OpenSSL::PKey::RSA.new(2048).to_pem

      unless ENV['CI']
        key_path.write(key)
        key_path.chmod(0o600)
      end

      key
    end

    # Returns the signing key as an OpenSSL::PKey::RSA instance.
    def signing_key
      OpenSSL::PKey::RSA.new(signing_key_content)
    end

    # Creates a new JWT for the given user, authorizing requests to ETModel.
    def user_jwt(user, scopes: [])
      unless Settings.etmodel_uri
        raise "No ETModel URI. Please set the 'etmodel_uri' setting in config/settings.local.yml."
      end

      payload = {
        iss: Doorkeeper::OpenidConnect.configuration.issuer.call(user, nil),
        aud: Settings.etmodel_uri,
        exp: 1.minute.from_now.to_i,
        iat: Time.now.to_i,
        scopes:,
        sub: user.id,
        user: user.as_json(only: %i[id name])
      }

      key = signing_key
      JWT.encode(payload, key, 'RS256', typ: 'JWT', kid: key.to_jwk['kid'])
    end

    # Returns a Faraday client for a user which will send requests to ETModel.
    def etmodel_client(user, scopes: [])
      Faraday.new(Settings.etmodel_uri) do |conn|
        conn.request(:authorization, 'Bearer', -> { user_jwt(user, scopes:) })
        conn.request(:json)
        conn.response(:json)

        conn.adapter(Faraday.default_adapter)
      end
    end
  end
end
