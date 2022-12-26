# frozen_string_literal: true

RSpec.describe Users::SessionsController do
  let(:user) { create(:user) }

  let(:application) do
    OAuthApplication.create!(
      name: 'Test Application',
      uri: 'https://example.com',
      redirect_uri: 'https://example.com/auth/callback',
      owner: user
    )
  end

  let(:token) do
    Doorkeeper::AccessToken.create!(
      application:,
      resource_owner_id: user.id
    )
  end

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  context 'when signing out with an access token' do
    before { sign_in(user) }

    it 'redirects to the application URL' do
      delete :destroy, params: { access_token: token.token }
      expect(response).to redirect_to('https://example.com')
    end

    it 'revokes the token' do
      expect { delete(:destroy, params: { access_token: token.token }) }
        .to change { token.reload.revoked? }.from(false).to(true)
    end
  end

  context 'when signing out with no access token' do
    before { sign_in(user) }

    it 'redirects to ETModel' do
      delete :destroy
      expect(response).to redirect_to(Settings.etmodel_uri)
    end
  end

  context 'when signing out with an access token that does not exist' do
    before { sign_in(user) }

    it 'redirects to ETModel' do
      delete :destroy, params: { access_token: 'invalid' }
      expect(response).to redirect_to(Settings.etmodel_uri)
    end
  end

  context 'when signing out with an access token that belongs to someone else' do
    before do
      token.update!(resource_owner_id: create(:user).id)
      sign_in(user)
    end

    it 'redirects to ETModel' do
      delete :destroy, params: { access_token: 'invalid' }
      expect(response).to redirect_to(Settings.etmodel_uri)
    end

    it 'does not revoke the token' do
      expect { delete(:destroy, params: { access_token: token.token }) }
        .not_to change { token.reload.revoked? }.from(false)
    end
  end
end
