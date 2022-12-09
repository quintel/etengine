# frozen_string_literal: true

RSpec.describe 'Staff application', type: :system do
  it 'allows creating a new staff application' do
    admin = create(:admin)
    sign_in(admin)

    visit '/'

    within('#staff_application_etmodel') do
      fill_in 'Hosted at', with: 'https://example.com'
      click_button 'Create application'
    end

    oauth_app = admin.staff_applications.find_by!(name: 'etmodel').application

    expect(page).to have_content('The application was updated.')
    expect(page).to have_content(oauth_app.uid)
    expect(page).to have_content(oauth_app.secret)
  end

  it 'allows updating a new staff application' do
    admin = create(:admin)
    CreateStaffApplication.call(admin, ETEngine::StaffApplications.find('etmodel'))

    sign_in(admin)

    visit '/'

    within('#staff_application_etmodel') do
      fill_in 'Hosted at', with: 'https://my-site.test'
      click_button 'Change'
    end

    oauth_app = admin.staff_applications.find_by!(name: 'etmodel').application

    expect(page).to have_content('The application was updated.')
    expect(page).to have_content(oauth_app.uid)
    expect(page).to have_content(oauth_app.secret)

    oauth_app.reload

    expect(oauth_app.uri).to eq('https://my-site.test')
    expect(oauth_app.redirect_uri).to eq('https://my-site.test/auth/identity/callback')
  end
end
