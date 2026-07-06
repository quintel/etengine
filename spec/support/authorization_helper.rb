# frozen_string_literal: true

module AuthorizationHelper
  def self.key
    @key ||= OpenSSL::PKey::RSA.new(2048)
  end

  def access_token_header(user = nil, scopes = [])
    user ? { 'Authorization' => "Bearer #{generate_jwt(user, scopes: match_scopes(scopes))}" } : {}
  end

  def generate_jwt(user, **kwargs)
    allow(Identity::TokenDecoder).to receive(:jwk_set).and_return(
      'keys' => [JWT::JWK.new(AuthorizationHelper.key.public_key, 'test_key').export]
    )

    JWT.encode(jwt_payload(user, **kwargs), AuthorizationHelper.key, 'RS256', kid: 'test_key')
  end

  def jwt_payload(
    user,
    aud: Settings.identity.client_uri,
    iat: Time.now.to_i,
    exp: 1.hour.from_now.to_i,
    scopes: []
  )
    {
      'iss' => Settings.identity.issuer,
      'aud' => aud,
      'iat' => iat,
      'exp' => exp,
      'sub' => user.id,
      'user' => {
        'id' => user.id,
        'name' => user.name,
        'email' => user.email
      },
      'scopes' => scopes
    }
  end

  def match_scopes(scopes)
    case scopes
    when :public
      'public'
    when :read
      'public scenarios:read'
    when :write
      'public scenarios:read scenarios:write'
    when :delete
      'public scenarios:read scenarios:write scenarios:delete'
    else
      scopes.to_s
    end
  end

  def stub_faraday_422(body)
    faraday_response = instance_double(Faraday::Response)
    allow(faraday_response).to receive(:[]).with(:body).and_return('errors' => body)
    Faraday::UnprocessableEntityError.new(nil, faraday_response)
  end
end
