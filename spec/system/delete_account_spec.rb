# frozen_string_literal: true

RSpec.describe 'Registrations', type: :system do
  let(:user) { create(:user) }

  before do
    conn = Faraday.new do |builder|
      builder.adapter(:test) do |stub|
        stub.get('/api/v1/saved_scenarios') do
          [
            200,
            { 'Content-Type' => 'application/json' },
            { 'meta' => { 'total' => 10 }, data: [] }
          ]
        end

        stub.get('/api/v1/transition_paths') do
          [
            200,
            { 'Content-Type' => 'application/json' },
            { 'meta' => { 'total' => 3 }, data: [] }
          ]
        end

        stub.delete('/api/v1/user') do
          [200, { 'Content-Type' => 'application/json' }, {}]
        end
      end
    end

    allow(ETEngine::Auth).to receive(:etmodel_client).and_return(conn)
  end

  it 'allows deleting the account' do
    sign_in(user)

    # Create some data for the user.
    create(:scenario, owner: user)
    create(:scenario, owner: user)
    create(:personal_access_token, user:)

    visit '/identity'

    click_link 'Delete account'

    expect(page).to have_text('You are about to delete your account!')
    expect(page).to have_text('2 scenarios')
    expect(page).to have_text('10 saved scenarios')
    expect(page).to have_text('3 transition paths')
    expect(page).to have_text('One personal access token')

    fill_in 'Password', with: user.password

    begin
      click_button 'Permanently delete account'
    rescue ActionController::RoutingError
      # This is raised because it redirects to ETModel, which isn't available in tests.
    end

    expect(User.where(id: user.id).count).to eq(0)
  end

  it 'shows an error when entering an invalid password' do
    sign_in(user)

    visit '/identity'

    click_link 'Delete account'

    fill_in 'Password', with: '_invalid_'
    click_button 'Permanently delete account'

    expect(page).to have_text('Current password is invalid')
  end

  it 'shows an error when entering no password' do
    sign_in(user)

    visit '/identity'

    click_link 'Delete account'

    fill_in 'Password', with: ''
    click_button 'Permanently delete account'

    expect(page).to have_text("Current password can't be blank")
  end
end
