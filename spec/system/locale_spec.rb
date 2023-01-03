# frozen_string_literal: true

RSpec.describe 'Locales', type: :system do
  it 'allows switching the language' do
    sign_in(create(:user))

    visit '/identity/profile'
    expect(page).to have_css('header button', text: 'Sign out')

    visit '/identity/profile?locale=nl'
    expect(page).to have_css('header button', text: 'Uitloggen')

    visit '/identity/profile?locale=en'
    expect(page).to have_css('header button', text: 'Sign out')

    visit '/identity/profile?locale=de'
    expect(page).to have_css('header button', text: 'Sign out')
  ensure
    I18n.locale = :en # rubocop:disable Rails/I18nLocaleAssignment
  end
end
