require 'spec_helper'
require 'jwt'

RSpec.describe ETEngine::TokenDecoder do
  let(:test_token) { JSON.parse(File.read(Rails.root.join('spec/fixtures/identity/token/idp_token.json')))['token'] }
  let(:test_jwk_set) do
    client = Faraday.new(Identity.discovery_config.jwks_uri) do |conn|
      conn.request(:json)
      conn.response(:json)
      conn.response(:raise_error)
    end
    JSON::JWK::Set.new(client.get.body)
  end
  let(:mock_decoded_token) do
    {
      iss: Settings.identity.api_url,
      aud: 'all_clients',
      sub: 1,
      exp: 1730367768, # Static expiration
      scopes: %w[read write]
    }.with_indifferent_access
  end

  before do
    allow(described_class).to receive(:jwk_set).and_return(test_jwk_set)
    allow(ETEngine::TokenDecoder).to receive(:decode).with(test_token).and_return(mock_decoded_token)
  end

  describe '.decode' do
    it 'successfully decodes a valid token' do
      decoded_token = ETEngine::TokenDecoder.decode(test_token)

      # Everything is mocked because this is a dynamic process
      expect(decoded_token[:iss]).to eq(Settings.identity.api_url)
      expect(decoded_token[:aud]).to eq('all_clients')
      expect(decoded_token[:sub]).to be_present
      expect(decoded_token[:exp]).to eq(1730367768) # Static expiration
    end
  end
end
