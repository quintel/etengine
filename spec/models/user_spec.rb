# frozen_string_literal: true

RSpec.describe User do
  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to have_many(:scenarios) }

  context 'when the user is not an admin' do
    let(:roles) { create(:user).roles }

    it 'has the user role' do
      expect(roles).to include('user')
    end

    it 'does not have the admin role' do
      expect(roles).not_to include('admin')
    end
  end

  context 'when the user is an admin' do
    let(:roles) { create(:admin).roles }

    it 'has the user role' do
      expect(roles).to include('user')
    end

    it 'has the admin role' do
      expect(roles).to include('admin')
    end
  end

  pending 'when a ScenarioUser with the same email existed before the user was created' do
    let(:user) { create(:user, email: 'foo@bar.com') }

    before do
      create(:scenario_user, user_email: 'foo@bar.com', user_id: nil)
    end

    it 'couples the new user' do
      expect(user.scenario_users.count).to be_positive
    end

    it 'shows the user has access to one scenario' do
      expect(user.scenarios.count).to be_positive
    end
  end
end
