# frozen_string_literal: true

module AuthorizationHelper
  require 'jwt'
  def access_token_header(user, scopes, expires_in: 1.hour)
    token = mock_jwt(user, scopes, expires_in: expires_in)
    { 'Authorization' => "Bearer #{token}" }
  end

  def mock_jwt(user, scopes, client_id: 'Mock_client_id', expires_in: 1.hour)
    scopes =
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

    # Define the payload for the JWT
    payload = {
      iss: Settings.identity.api_url, # Replace with the correct issuer from your app
      aud: client_id,
      exp: expires_in.from_now.to_i,
      iat: Time.now.to_i,
      scopes: scopes.split,
      sub: user.id,
      user: user.as_json(only: %i[id admin]) # Include only the desired user fields
    }

    key = OpenSSL::PKey::RSA.generate(2048)
    token = JWT.encode(payload, key, "RS256", typ: "JWT", kid: key.to_jwk["kid"])

    # Stub the decoding logic to return the payload
    allow(ETEngine::TokenDecoder).to receive(:decode).and_return(payload)

    token # Return the encoded JWT token
  end

  def stub_faraday_422(body)
    faraday_response = instance_double(Faraday::Response)
    allow(faraday_response).to receive(:[]).with(:body).and_return('errors' => body)
    Faraday::UnprocessableEntityError.new(nil, faraday_response)
  end
end
