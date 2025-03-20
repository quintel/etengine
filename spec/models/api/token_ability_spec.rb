# frozen_string_literal: true

require 'cancan/matchers'

RSpec.describe Api::TokenAbility do
  let(:user) { create(:user, roles:) }
  let(:roles) { :scenario_viewer }
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
  let(:scopes) { '' }

  let(:mock_decoded_token) do
    {
      iss: Settings.identity.api_url,
      aud: 'all_clients',
      sub: user.id,
      exp: 1730367768, # Static future expiration
      scopes: scopes
    }.with_indifferent_access
  end

  before do
    # Stub Faraday to prevent actual HTTP requests
    allow(Faraday).to receive(:new).and_return(
      double('Faraday::Connection').tap do |connection|
        allow(connection).to receive(:get).and_return(
          double('Faraday::Response', body: mock_jwk_set.to_json)
        )
      end
    )

    # Stub the jwk_set method to return the mock JWK set
    allow(described_class).to receive(:jwk_set).and_return(JSON::JWK::Set.new(mock_jwk_set))

    # Mock the TokenDecoder behavior
    allow(ETEngine::TokenDecoder).to receive(:decode).with(test_token).and_return(mock_decoded_token)
  end

  let(:ability) { described_class.new(mock_decoded_token, user) }

  let!(:public_scenario) { create(:scenario, user: nil, private: false) }
  let!(:owned_public_scenario) { create(:scenario, user: user, private: false) }
  let!(:owned_private_scenario) { create(:scenario, user: user, private: true) }
  let!(:other_public_scenario) { create(:scenario, user: create(:user), private: false) }
  let!(:other_private_scenario) { create(:scenario, user: create(:user), private: true) }

  # ------------------------------------------------------------------------------------------------

  shared_examples_for 'a token without the "scenarios:read" scope' do
    it 'may view an unowned public scenario' do
      expect(ability).to be_able_to(:read, public_scenario)
    end

    it 'may view a self-owned public scenario' do
      expect(ability).to be_able_to(:read, owned_public_scenario)
    end

    it 'may view an other-owned public scenario' do
      expect(ability).to be_able_to(:read, other_public_scenario)
    end

    it 'may not view an owned private scenario' do
      expect(ability).not_to be_able_to(:read, other_private_scenario)
    end

    context 'when admin' do
      let(:user) { create(:user, admin: true, roles:) }

      it 'may not view an owned private scenario' do
        expect(ability).not_to be_able_to(:read, other_private_scenario)
      end
    end
  end

  shared_examples_for 'a token with the "scenarios:read" scope' do
    it 'may view an unowned public scenario' do
      expect(ability).to be_able_to(:read, public_scenario)
    end

    it 'may view a self-owned public scenario' do
      expect(ability).to be_able_to(:read, owned_public_scenario)
    end

    it 'may view an other-owned public scenario' do
      expect(ability).to be_able_to(:read, other_public_scenario)
    end

    it 'may view an owned private scenario' do
      expect(ability).to be_able_to(:read, owned_private_scenario)
    end

    context 'when admin' do
      let(:user) { create(:user, admin: true, roles:) }

      it 'may view an owned private scenario' do
        expect(ability).to be_able_to(:read, other_private_scenario)
      end
    end
  end

  shared_examples_for 'a token with the "scenarios:write" scope' do
    it 'may create a new scenario' do
      expect(ability).to be_able_to(:create, Scenario)
    end

    it 'may change an unowned public scenario' do
      expect(ability).to be_able_to(:update, public_scenario)
    end

    it 'may change a self-owned public scenario' do
      expect(ability).to be_able_to(:update, owned_public_scenario)
    end

    it 'may change a self-owned private scenario' do
      expect(ability).to be_able_to(:update, owned_private_scenario)
    end

    it 'may not change an other-owned public scenario' do
      expect(ability).not_to be_able_to(:update, other_public_scenario)
    end

    it 'may not change an other-owned private scenario' do
      expect(ability).not_to be_able_to(:update, other_private_scenario)
    end

    it 'may clone an unowned public scenario' do
      expect(ability).to be_able_to(:clone, public_scenario)
    end

    it 'may clone a self-owned public scenario' do
      expect(ability).to be_able_to(:clone, owned_public_scenario)
    end

    it 'may clone an other-owned public scenario' do
      expect(ability).to be_able_to(:clone, other_public_scenario)
    end

    it 'may clone a self-owned private scenario' do
      expect(ability).to be_able_to(:clone, owned_private_scenario)
    end

    it 'may not clone an other-owned private scenario' do
      expect(ability).not_to be_able_to(:clone, other_private_scenario)
    end

    context 'when admin' do
      let(:user) { create(:user, admin: true, roles:) }

      it 'may change an other-owned public scenario' do
        expect(ability).to be_able_to(:update, other_public_scenario)
      end

      it 'may change an other-owned private scenario' do
        expect(ability).to be_able_to(:update, other_private_scenario)
      end

      it 'may clone an other-owned private scenario' do
        expect(ability).to be_able_to(:clone, other_private_scenario)
      end
    end
  end

  shared_examples_for 'a token without the "scenarios:write" scope' do
    it 'may not create a new scenario' do
      expect(ability).not_to be_able_to(:create, Scenario)
    end

    it 'may not change an unowned public scenario' do
      expect(ability).not_to be_able_to(:update, public_scenario)
    end

    it 'may not change a self-owned public scenario' do
      expect(ability).not_to be_able_to(:update, owned_public_scenario)
    end

    it 'may not change a self-owned private scenario' do
      expect(ability).not_to be_able_to(:update, owned_private_scenario)
    end

    it 'may not change an other-owned public scenario' do
      expect(ability).not_to be_able_to(:update, other_public_scenario)
    end

    it 'may not change an other-owned private scenario' do
      expect(ability).not_to be_able_to(:update, other_private_scenario)
    end

    it 'may not clone an unowned public scenario' do
      expect(ability).not_to be_able_to(:clone, public_scenario)
    end

    it 'may not clone an owned public scenario' do
      expect(ability).not_to be_able_to(:clone, owned_public_scenario)
    end

    it 'may not clone an owned private scenario' do
      expect(ability).not_to be_able_to(:clone, owned_private_scenario)
    end

    context 'when admin' do
      let(:user) { create(:user, admin: true, roles:) }

      it 'may not change an other-owned public scenario' do
        expect(ability).not_to be_able_to(:update, other_public_scenario)
      end

      it 'may not change an other-owned private scenario' do
        expect(ability).not_to be_able_to(:update, other_private_scenario)
      end

      it 'may not clone an other-owned private scenario' do
        expect(ability).not_to be_able_to(:clone, other_private_scenario)
      end
    end
  end

  shared_examples_for 'a token with the "scenarios:delete" scope' do
    it 'may not delete an unowned public scenario' do
      expect(ability).not_to be_able_to(:destroy, public_scenario)
    end

    it 'may delete a self-owned public scenario' do
      expect(ability).to be_able_to(:destroy, owned_public_scenario)
    end

    it 'may delete a self-owned private scenario' do
      expect(ability).to be_able_to(:destroy, owned_private_scenario)
    end

    it 'may not delete an other-owned public scenario' do
      expect(ability).not_to be_able_to(:destroy, other_public_scenario)
    end

    it 'may not delete an other-owned private scenario' do
      expect(ability).not_to be_able_to(:destroy, other_private_scenario)
    end

    context 'when admin' do
      let(:user) { create(:user, admin: true, roles:) }

      it 'may delete an other-owned public scenario' do
        expect(ability).to be_able_to(:destroy, other_public_scenario)
      end

      it 'may delete an other-owned private scenario' do
        expect(ability).to be_able_to(:destroy, other_private_scenario)
      end
    end
  end

  shared_examples_for 'a token without the "scenarios:delete" scope' do
    it 'may not delete an unowned public scenario' do
      expect(ability).not_to be_able_to(:destroy, public_scenario)
    end

    it 'may not delete a self-owned public scenario' do
      expect(ability).not_to be_able_to(:destroy, owned_public_scenario)
    end

    it 'may not delete a self-owned private scenario' do
      expect(ability).not_to be_able_to(:destroy, owned_private_scenario)
    end

    it 'may not delete an other-owned public scenario' do
      expect(ability).not_to be_able_to(:destroy, other_public_scenario)
    end

    it 'may not delete an other-owned private scenario' do
      expect(ability).not_to be_able_to(:destroy, other_private_scenario)
    end

    context 'when admin' do
      let(:user) { create(:user, admin: true, roles:) }

      it 'may not delete an other-owned public scenario' do
        expect(ability).not_to be_able_to(:destroy, other_public_scenario)
      end

      it 'may not delete an other-owned private scenario' do
        expect(ability).not_to be_able_to(:destroy, other_private_scenario)
      end
    end
  end

  # ------------------------------------------------------------------------------------------------

  context 'when the token scope is "public"' do
    # Read
    include_examples 'a token without the "scenarios:read" scope'

    # Update
    include_examples 'a token without the "scenarios:write" scope'

    # Delete
    include_examples 'a token without the "scenarios:delete" scope'
  end

  # ------------------------------------------------------------------------------------------------

  context 'when the token scope is "scenarios:read"' do
    let(:scopes) { 'scenarios:read' }

    include_examples 'a token with the "scenarios:read" scope'
    include_examples 'a token without the "scenarios:write" scope'
    include_examples 'a token without the "scenarios:delete" scope'
  end

  # ------------------------------------------------------------------------------------------------

  context 'when the token scope is "scenarios:read scenarios:write"' do
    let(:scopes) { 'scenarios:read scenarios:write' }

    include_examples 'a token with the "scenarios:read" scope'
    include_examples 'a token with the "scenarios:write" scope'
    include_examples 'a token without the "scenarios:delete" scope'
  end

  # ------------------------------------------------------------------------------------------------

  context 'when the token scope is "scenarios:read scenarios:write scenarios:delete"' do
    let(:scopes) { 'scenarios:read scenarios:write scenarios:delete' }

    include_examples 'a token with the "scenarios:read" scope'
    include_examples 'a token with the "scenarios:write" scope'
    include_examples 'a token with the "scenarios:delete" scope'
  end
end
