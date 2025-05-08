# frozen_string_literal: true

module ETEngine
  # Handles JWT decoding, verification, and fetching.
  module TokenDecoder
    module_function

    DecodeError = Class.new(StandardError)

    # Decodes and verifies a JWT.
    def decode(token)
      decoded = JSON::JWT.decode(strip_etm_prefix(token), jwk)

      unless decoded[:iss] == Settings.identity.issuer &&
             decoded[:aud].include?(Settings.identity.client_uri) &&
             decoded[:sub].present? &&
             decoded[:exp] > Time.now.to_i
        Rails.logger.warn(
          "issuer #{decoded[:iss] == Settings.identity.issuer}: #{decoded[:iss]} \
            aud #{decoded[:aud].include?(Settings.identity.client_uri)} #{decoded[:aud]} \
            sub #{decoded[:sub].present?} \
            exp #{decoded[:exp] > Time.now.to_i} #{decoded[:exp]}
          "
        )
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

    def strip_etm_prefix(token)
      token.sub(/^etm_(beta_)?/, '')
    end
  end
end
