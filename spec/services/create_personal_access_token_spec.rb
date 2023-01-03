# frozen_string_literal: true

RSpec.describe CreatePersonalAccessToken do
  let(:user) { create(:user) }

  shared_examples_for 'creating a personal access token' do
    it 'is successful' do
      expect(action).to be_success
    end

    it 'creating a personal access token' do
      expect { action }.to change(user.personal_access_tokens, :count).by(1)
    end

    it 'creates an oauth access token' do
      expect { action }.to change(user.access_tokens, :count).by(1)
    end

    it 'sets the personal token name' do
      expect(action.value!.name).to eq('API access')
    end

    it 'associates the oauth token with the personal token' do
      expect(action.value!.oauth_access_token).to eq(user.access_tokens.last)
    end
  end

  shared_examples_for 'failing to create a personal access token' do
    it 'returns a failure' do
      expect(action).to be_failure
    end

    it 'creating a personal access token' do
      expect { action }.not_to change(user.personal_access_tokens, :count)
    end

    it 'creates an oauth access token' do
      expect { action }.not_to change(user.access_tokens, :count)
    end
  end

  # ------------------------------------------------------------------------------------------------

  context 'with an expiry date in the past' do
    let(:action) do
      described_class.call(user:, params: { name: 'API access', expires_in: -365 })
    end

    include_examples 'failing to create a personal access token'

    it 'sets the expiry date to 7 days from now' do
      expect(action.failure.errors[:expires_in]).to include('must be greater than 0')
    end
  end

  context 'with an expiry date 7 days from now' do
    let(:action) do
      described_class.call(user:, params: { name: 'API access', expires_in: 7 })
    end

    include_examples 'creating a personal access token'

    it 'sets the expiry date to 7 days from now' do
      expect(action.value!.oauth_access_token.expires_in).to eq(7.days.to_i)
    end
  end

  context 'with an expiry date a year from now' do
    let(:action) do
      described_class.call(user:, params: { name: 'API access', expires_in: 365 })
    end

    include_examples 'creating a personal access token'

    it 'sets the expiry date to one from now' do
      expect(action.value!.oauth_access_token.expires_in).to eq(365.days.to_i)
    end
  end

  context 'with no expiry date' do
    let(:action) do
      described_class.call(user:, params: { name: 'API access', expires_in: 'never' })
    end

    include_examples 'creating a personal access token'

    it 'sets no expiry date' do
      expect(action.value!.oauth_access_token.expires_in).to be_nil
    end
  end

  context 'with scopes that are not valid' do
    let(:action) do
      described_class.call(user:, params: { name: 'API access', permissions: 'invalid' })
    end

    include_examples 'failing to create a personal access token'

    it 'sets the public scope' do
      expect(action.failure.errors[:permissions]).to include('is not included in the list')
    end
  end

  context 'with permissions="write"' do
    let(:action) do
      described_class.call(user:, params: { name: 'API access', permissions: 'write' })
    end

    include_examples 'creating a personal access token'

    it 'sets scopes to "openid public scenarios:read scenarios:write"' do
      expect(action.value!.oauth_access_token.scopes.to_a)
        .to eq(%w[openid public scenarios:read scenarios:write])
    end
  end

  context 'with email_scope="1"' do
    let(:action) do
      described_class.call(user:, params: { name: 'API access', email_scope: '1' })
    end

    include_examples 'creating a personal access token'

    it 'sets scopes to "openid public email' do
      expect(action.value!.oauth_access_token.scopes.to_a) .to eq(%w[openid public email])
    end
  end

  context 'with profile_scope="1"' do
    let(:action) do
      described_class.call(user:, params: { name: 'API access', profile_scope: '1' })
    end

    include_examples 'creating a personal access token'

    it 'sets scopes to "openid public profile' do
      expect(action.value!.oauth_access_token.scopes.to_a) .to eq(%w[openid public profile])
    end
  end

  context 'when there is a single collision with the token' do
    before do
      allow(Doorkeeper::OAuth::Helpers::UniqueToken).to receive(:generate)
        .and_invoke(->(*) { 'token_abc' }, ->(*) { 'token_abc' }, ->(*) { 'token_123' })

      user.access_tokens.create!({})
    end

    let(:action) do
      described_class.call(user:, params: { name: 'API access' })
    end

    include_examples 'creating a personal access token'
  end

  context 'when there is a repeated collision with the token' do
    before do
      allow(Doorkeeper::OAuth::Helpers::UniqueToken).to receive(:generate).and_return('token_abc')

      user.access_tokens.create!({})
    end

    let(:action) do
      described_class.call(user:, params: { name: 'API access' })
    end

    it 'raises an error' do
      expect { action }.to raise_error(ActiveRecord::RecordInvalid, /Token has already been taken/)
    end
  end

  # ------------------------------------------------------------------------------------------------

  describe 'Params' do
    let(:attributes) do
      { name: 'My token' }
    end

    let(:params) do
      described_class::Params.new(attributes)
    end

    before do
      params.valid?
    end

    context 'when given no name' do
      let(:attributes) { super().merge(name: '') }

      it 'has an error on name' do
        expect(params.errors[:name]).to include("can't be blank")
      end
    end

    context 'when given expires_in=7' do
      let(:attributes) do
        super().merge(expires_in: 7)
      end

      it 'has no error on expires_in' do
        expect(params.errors[:expires_in]).to be_empty
      end

      it 'coerces the value to 7' do
        expect(params.expires_in).to eq(7)
      end

      it 'sets OAuth expires_at to 7 days from now' do
        expect(params.to_oauth_token_params[:expires_in]).to eq(7.days)
      end
    end

    context 'when given expires_in="7"' do
      let(:attributes) do
        super().merge(expires_in: '7')
      end

      it 'has no error on expires_in' do
        expect(params.errors[:expires_in]).to be_empty
      end

      it 'coerces the value to 7' do
        expect(params.expires_in).to eq(7)
      end
    end

    context 'when given expires_in=nil' do
      let(:attributes) do
        super().merge(expires_in: nil)
      end

      it 'has has an error on expires_in' do
        expect(params.errors[:expires_in]).to include('is not a number')
      end
    end

    context 'when given expires_in="never"' do
      let(:attributes) do
        super().merge(expires_in: 'never')
      end

      it 'has no error on expires_in' do
        expect(params.errors[:expires_in]).to be_empty
      end

      it 'coerces the value to nil' do
        expect(params.expires_in).to eq('never')
      end

      it 'sets OAuth expires_at to nil' do
        expect(params.to_oauth_token_params[:expires_in]).to eq(nil)
      end
    end

    context 'when given expires_in="invalid"' do
      let(:attributes) do
        super().merge(expires_in: 'invalid')
      end

      it 'has an error on expires_in' do
        expect(params.errors[:expires_in]).to include('is not a number')
      end
    end

    context 'when given expires_in=-1' do
      let(:attributes) do
        super().merge(expires_in: -1)
      end

      it 'has an error on expires_in' do
        expect(params.errors[:expires_in]).to include('must be greater than 0')
      end
    end
  end
end
