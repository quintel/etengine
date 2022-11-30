# frozen_string_literal: true

RSpec.describe 'Sessions', type: :system do
  it 'allows signing in as a user' do
    create(:user, email: 'hello@example.org', password: 'password123')

    visit '/identity/sign_in'

    fill_in 'E-mail address', with: 'hello@example.org'
    fill_in 'Password', with: 'password123'

    click_button 'Continue'

    expect(page).to be_signed_in_page
  end

  it 'does not sign in when providing an invalid e-mail' do
    visit '/identity/sign_in'

    fill_in 'E-mail address', with: 'hello@example.org'
    fill_in 'Password', with: 'password123'

    click_button 'Continue'

    expect(page).to have_text('Sign in to your account to continue')
  end

  it 'does not sign in when providing an invalid password' do
    create(:user, email: 'hello@example.org', password: 'password123')

    visit '/identity/sign_in'

    fill_in 'E-mail address', with: 'hello@example.org'
    fill_in 'Password', with: 'password456'

    click_button 'Continue'

    expect(page).to have_text('Sign in to your account to continue')
  end

  it 'does not sign in when providing no credentials' do
    visit '/identity/sign_in'

    fill_in 'E-mail address', with: ''
    fill_in 'Password', with: ''

    click_button 'Continue'

    expect(page).to have_text('Sign in to your account to continue')
  end

  it 'signs in when the user has a legacy password with legacy_password_salt' do
    salt = SecureRandom.hex
    user = create(:user, email: 'hello@example.org')

    User.update(
      user.id,
      encrypted_password: BCrypt::Password.create("my password#{salt}", cost: 4),
      legacy_password_salt: salt
    )

    visit '/identity/sign_in'

    fill_in 'E-mail address', with: 'hello@example.org'
    fill_in 'Password', with: 'my password'

    expect { click_button('Continue') }.to(change { user.reload.encrypted_password })

    expect(page).to be_signed_in_page
    expect(user.legacy_password_salt).to be_nil
  end
end
