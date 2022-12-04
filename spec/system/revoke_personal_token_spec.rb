# frozen_string_literal: true

RSpec.describe 'Revoking a personal access token', type: :system do
  it 'revokes the token' do
    user = create(:user)
    CreatePersonalAccessToken.call(user:, params: { name: 'API access' })

    sign_in(user)

    visit '/identity/tokens'

    expect(page).to have_content('API access')

    click_button 'Revoke token'
    expect(page).to have_content('You have no access tokens')
  end
end
