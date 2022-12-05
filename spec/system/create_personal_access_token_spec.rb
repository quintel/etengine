# frozen_string_literal: true

RSpec.describe 'Revoking a personal access token', type: :system do
  context 'with valid params' do
    it 'creates a token' do
      user = create(:user)
      sign_in(user)

      visit '/identity/tokens/new'

      fill_in 'Token name', with: 'API access'
      select '7 days', from: 'Expiration'
      choose 'Read public and private scenarios'

      click_button 'Create token'

      expect(page).to have_content('Token created')
      expect(page).to have_content('API access')

      # Scopes

      expect(page).to have_css(
        '[data-testid="scope:public"]:not([aria-hidden="true"])',
        text: 'Read public scenarios'
      )

      expect(page).to have_css(
        '[data-testid="scope:scenarios:read"]:not([aria-hidden="true"])',
        text: 'Read your private scenarios'
      )

      expect(page).to have_css(
        '[data-testid="scope:scenarios:write"][aria-hidden="true"]',
        text: 'Create new scenarios and change your public and private scenarios'
      )

      expect(page).to have_css(
        '[data-testid="scope:scenarios:delete"][aria-hidden="true"]',
        text: 'Delete your public and private scenarios'
      )
    end
  end

  context 'with no name' do
    it 'creates a token' do
      user = create(:user)
      sign_in(user)

      visit '/identity/tokens/new'

      fill_in 'Token name', with: ''
      select '7 days', from: 'Expiration'
      choose 'Read public and private scenarios'

      click_button 'Create token'

      expect(page).to have_content("Name can't be blank")
    end
  end
end
