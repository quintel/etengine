# frozen_string_literal: true

module ETEngine
  # Handles JWT decoding, verification, and fetching.
  module TokenDecoder
    module_function

    DecodeError = Class.new(StandardError)

    # Decodes and verifies a JWT.
    def decode(token)
      decoded = JSON::JWT.decode(token, jwk)

      unless decoded[:iss] == Settings.identity.issuer &&
             (
              decoded[:aud] == Settings.identity.client_uri ||
              decoded[:aud] == Settings.etmodel_uri
             ) &&
             decoded[:sub].present? &&
             decoded[:exp] > Time.now.to_i
        raise DecodeError, 'JWT verification failed'
      end

      decoded
    end

    # Fetches and caches the JWK from the IdP.
    def jwk
      jwk_cache.fetch('jwk_hash') do
        client = Faraday.new(Identity.discovery_config.jwks_uri) do |conn|
          conn.request(:json)
          conn.response(:json)
          conn.response(:raise_error)
        end

        JSON::JWK.new(client.get.body['keys'].first.symbolize_keys)
      end
    end

    # Handles caching of JWKs.
    def jwk_cache
      @jwk_cache ||=
        if Rails.env.development?
          ActiveSupport::Cache::MemoryStore.new
        else
          Rails.cache
        end
    end
  end
end
