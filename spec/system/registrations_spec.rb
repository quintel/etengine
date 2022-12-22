# frozen_string_literal: true

RSpec.describe 'Registrations', type: :system do
  before do
    ActionMailer::Base.deliveries.clear
  end

  # Given a Mail::Message, extracts the confirmation path from the message body.
  def confirmation_url_from_email(email)
    body = email.body
    match = body.match(%r{http://localhost:3000(/identity/confirmation\?confirmation_token=[^"]+)})

    raise 'No reset password link found' unless match

    match[1]
  end

  # Registering an account
  # ----------------------

  context 'when registering an account' do
    it 'allows registering an account' do
      visit '/identity/sign_up'

      fill_in 'Your name', with: 'My name'
      fill_in 'E-mail address', with: 'me@example.org'
      fill_in 'Password', with: 'password123'

      click_button 'Sign up'

      visit '/identity'

      expect(page).to be_signed_in_page

      # Confirm
      visit confirmation_url_from_email(ActionMailer::Base.deliveries.first)

      expect(page).to have_text('Your email address has been successfully confirmed')
      expect(page).to have_text('My name')
    end

    it 'shows an error when registering without a name' do
      visit '/identity/sign_up'

      fill_in 'E-mail address', with: 'me@example.org'
      fill_in 'Password', with: 'password123'
      click_button 'Sign up'

      expect(page).to have_text("Your name can't be blank")
    end

    it 'shows an error when registering without a password' do
      visit '/identity/sign_up'

      fill_in 'Your name', with: 'My name'
      fill_in 'E-mail address', with: 'me@example.org'
      click_button 'Sign up'

      expect(page).to have_text("Password can't be blank")
    end

    it 'shows an error when registering without an e-mail address' do
      visit '/identity/sign_up'

      fill_in 'Your name', with: 'My name'
      fill_in 'Password', with: 'password123'
      click_button 'Sign up'

      expect(page).to have_text("E-mail address can't be blank")
    end

    it 'shows an error when registering with an existing e-mail address' do
      create(:user, email: 'me@example.org')

      visit '/identity/sign_up'

      fill_in 'Your name', with: 'My name'
      fill_in 'E-mail address', with: 'me@example.org'
      fill_in 'Password', with: 'password123'
      click_button 'Sign up'

      expect(page).to have_text('E-mail address has already been taken')
    end
  end

  # Changing name
  # ------------------

  context 'when changing the account name' do
    let(:user) do
      create(:user, name: 'John Doe')
    end

    before do
      allow(Identity::SyncUserJob).to receive(:perform_later)
    end

    context 'when visiting signed out' do
      it 'tells the user to sign in' do
        visit '/identity/change_name'
        expect(page).to have_text('You need to sign in or sign up before continuing.')
      end
    end

    context 'when providing a valid name' do
      before do
        sign_in(user)
      end

      it 'changes the password and redirects' do
        click_link 'Change name…'

        fill_in 'New name', with: 'Jane Doe'

        click_button 'Change name'

        expect(page).to have_text('Name changed')
        expect(page).to be_signed_in_page
      end
    end

    context 'when providing a blank name' do
      before { sign_in(user) }

      it 'shows an error' do
        visit '/identity/change_name'

        fill_in 'New name', with: ''

        click_button 'Change name'

        expect(page).to have_text("Your name can't be blank")
      end
    end
  end

  # Changing e-mail address
  # -----------------------

  context 'when changing e-mail address' do
    let(:user) do
      create(:user, email: 'hello@example.org', password: 'password123')
    end

    context 'when visiting signed out' do
      it 'tells the user to sign in' do
        visit '/identity/change_password'
        expect(page).to have_text('You need to sign in or sign up before continuing.')
      end
    end

    context 'when providing the correct current password and a valid new address' do
      before do
        sign_in(user)
      end

      it 'changes the address and redirects' do
        click_link 'Change e-mail address…'

        fill_in 'Current password', with: 'password123'
        fill_in 'New e-mail address', with: 'hi@example.org'

        click_button 'Change e-mail address'

        expect(page).to have_text('E‑mail changed')
        expect(page).to be_signed_in_page
      end
    end

    context 'when providing the incorrect current password and a valid new address' do
      before { sign_in(user) }

      it 'shows an error' do
        click_link 'Change e-mail address…'

        fill_in 'Current password', with: 'password456'
        fill_in 'New e-mail address', with: 'hi@example.org'

        click_button 'Change e-mail address'

        expect(page).to have_text('Current password is invalid')
      end
    end

    context 'when providing the correct current password and an invalid new address' do
      before { sign_in(user) }

      it 'shows an error' do
        click_link 'Change e-mail address…'

        fill_in 'Current password', with: 'password123'
        fill_in 'New e-mail address', with: ''

        click_button 'Change e-mail address'

        expect(page).to have_text("E-mail address can't be blank")
      end
    end
  end

  # Changing password
  # ------------------

  context 'when changing password' do
    let(:user) do
      create(:user, password: 'password123')
    end

    context 'when visiting signed out' do
      it 'tells the user to sign in' do
        visit '/identity/change_password'
        expect(page).to have_text('You need to sign in or sign up before continuing.')
      end
    end

    context 'when providing the correct current password and a valid new password' do
      before do
        sign_in(user)
      end

      it 'changes the password and redirects' do
        click_link 'Change password…'

        fill_in 'Current password', with: 'password123'
        fill_in 'New password', with: 'password456'

        click_button 'Change password'

        expect(page).to have_text('Password changed')
        expect(page).to be_signed_in_page
      end
    end

    context 'when providing the incorrect current password and a valid new password' do
      before { sign_in(user) }

      it 'shows an error' do
        visit '/identity/change_password'

        fill_in 'Current password', with: 'password456'
        fill_in 'New password', with: 'password456'

        click_button 'Change password'

        expect(page).to have_text('Current password is invalid')
      end
    end

    context 'when providing the correct current password and an invalid new password' do
      before { sign_in(user) }

      it 'shows an error' do
        visit '/identity/change_password'

        fill_in 'Current password', with: 'password123'
        fill_in 'New password', with: 'pa'

        click_button 'Change password'

        expect(page).to have_text('Password is too short (minimum is 8 characters)')
      end
    end
  end
end
