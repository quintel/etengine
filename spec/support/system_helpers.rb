# frozen_string_literal: true

module SystemHelpers
  RSpec::Matchers.define(:be_signed_in_page) do
    match do |actual|
      have_css('header button', text: 'Sign out').matches?(actual)
    end
  end

  def sign_in(user_or_email, password = nil)
    if user_or_email.is_a?(User)
      password = user_or_email.password
      user_or_email = user_or_email.email
    end

    visit('/identity/sign_in')

    fill_in('E-mail', with: user_or_email)
    fill_in('Password', with: password)

    click_button('Continue')
  end
end
