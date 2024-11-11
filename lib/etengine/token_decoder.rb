# frozen_string_literal: true

module ETEngine
  # Decodes and verifies a token sent by MyETM.
  module TokenDecoder
    DecodeError = Class.new(StandardError)

    def jwt_format?(token)
      token.count('.') > 1
    end

    def decode_jwt(jwt_token)
      decoded = JSON::JWT.decode(jwt_token, jwk_set)

      unless decoded[:iss] == Settings.identity.api_url &&
             decoded[:aud] == Settings.identity.ete_uri &&
             decoded[:sub].present? &&
             decoded[:exp] > Time.now.to_i
        raise DecodeError, 'JWT verification failed'
      end

      decoded
    end

    def exchange_bearer_for_jwt(bearer_token)
      idp_url = Settings.identity.token_exchange_url || 'http://localhost:3002/identity/token_exchange'
      response = Faraday.post(idp_url) do |req|
        req.headers['Authorization'] = "Bearer #{bearer_token}"
        req.headers['Content-Type'] = 'application/json'
      end

      return JSON.parse(response.body)['jwt'] if response.success?
      nil
    end

    def decode(token)
      # Check if the token is a JWT or a Bearer token
      if jwt_format?(token)
        decoded_jwt = decode_jwt(token)
      else
        jwt_token = exchange_bearer_for_jwt(token)
        raise DecodeError, 'Failed to exchange Bearer token for JWT' unless jwt_token
        decoded_jwt = decode_jwt(jwt_token)
      end

      decoded_jwt
    end

    def jwk_set
      jwk_cache.fetch('jwk_hash') do
        client = Faraday.new(Identity.discovery_config.jwks_uri) do |conn|
          conn.request(:json)
          conn.response(:json)
          conn.response(:raise_error)
        end

        JSON::JWK::Set.new(client.get.body)
      end
    end

    def jwk_cache
      @jwk_cache ||=
        if Rails.env.development?
          ActiveSupport::Cache::MemoryStore.new
        else
          Rails.cache
        end
    end

    module_function :decode, :jwt_format?, :decode_jwt, :exchange_bearer_for_jwt, :jwk_set, :jwk_cache
  end
end
