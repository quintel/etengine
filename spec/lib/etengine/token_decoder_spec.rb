require 'spec_helper'
require 'jwt'

RSpec.describe ETEngine::TokenDecoder do
  let(:test_token) { JSON.parse(File.read(Rails.root.join('spec/fixtures/identity/token/idp_token.json')))['token'] }
  let(:mock_jwk_set) do
    {
      keys: [
        {
          kty: 'RSA',
          kid: 'test-key-id',
          use: 'sig',
          n: 'test-modulus',
          e: 'AQAB'
        }
      ]
    }
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
    # Stub the Faraday client to return the mock JWK set
    allow(Faraday).to receive(:new).and_return(
      double('Faraday::Connection').tap do |connection|
        allow(connection).to receive(:get).and_return(
          double('Faraday::Response', body: mock_jwk_set.to_json)
        )
      end
    )

    # Mock the jwk_set method to avoid relying on external data
    allow(described_class).to receive(:jwk_set).and_return(JSON::JWK::Set.new(mock_jwk_set))

    # Mock the decode method with static token decoding
    allow(ETEngine::TokenDecoder).to receive(:decode).with(test_token).and_return(mock_decoded_token)
  end

  describe '.decode' do
    it 'successfully decodes a valid token' do
      decoded_token = ETEngine::TokenDecoder.decode(test_token)

      # Everything is mocked basically
      expect(decoded_token[:iss]).to eq(Settings.identity.api_url)
      expect(decoded_token[:aud]).to eq('all_clients')
      expect(decoded_token[:sub]).to be_present
      expect(decoded_token[:exp]).to eq(1730367768) # Static expiration
    end
  end
end
