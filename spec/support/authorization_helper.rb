# frozen_string_literal: true

module AuthorizationHelper
  require 'ostruct'

  def access_token_header(user, scopes, expires_in: 1.hour)
    token = mock_jwt(user, scopes, expires_in: expires_in)
    { 'Authorization' => "Bearer #{token}" }
  end

  def mock_jwt(user, scopes, expires_in: 1.hour)
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

    # Mock the decoded token payload using OpenStruct for method-like access
    mock_decoded_token = OpenStruct.new(
      iss: Settings.identity.api_url,
      aud: 'Settings.identity.ete_uri',
      exp: expires_in.from_now.to_i,
      iat: Time.now.to_i,
      sub: user.id,
      scopes: scopes.split
    )

    # Stub the `decode` method to return this object whenever called
    allow(ETEngine::TokenDecoder).to receive(:decode).and_return(mock_decoded_token)

    # Return a placeholder token string since the actual value won't be decoded
    "mocked.token.string"
  end

  def stub_faraday_422(body)
    faraday_response = instance_double(Faraday::Response)
    allow(faraday_response).to receive(:[]).with(:body).and_return('errors' => body)
    Faraday::UnprocessableEntityError.new(nil, faraday_response)
  end
end
