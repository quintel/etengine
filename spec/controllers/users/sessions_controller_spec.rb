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

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  context 'when signing out with an application UID' do
    before { sign_in(user) }

    it 'redirects to the application URL' do
      delete :destroy, params: { client_id: application.uid }
      expect(response).to redirect_to('https://example.com')
    end
  end

  context 'when signing out with no application UID' do
    before { sign_in(user) }

    it 'redirects to the root URL' do
      delete :destroy
      expect(response).to redirect_to(root_url)
    end
  end

  context 'when signing out with an application UID that does not exist' do
    before { sign_in(user) }

    it 'redirects to the root URL' do
      delete :destroy, params: { client_id: 'invalid' }
      expect(response).to redirect_to(root_url)
    end
  end
end
