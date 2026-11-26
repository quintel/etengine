# frozen_string_literal: true

RSpec.describe User do
  it { is_expected.to validate_presence_of(:name) }

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
end
