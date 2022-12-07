# frozen_string_literal: true

RSpec.describe User do
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to have_many(:access_grants) }
  it { is_expected.to have_many(:access_tokens) }
  it { is_expected.to have_many(:oauth_applications) }
  it { is_expected.to have_many(:scenarios) }

  describe '#valid_password?' do
    let(:user) { create(:user, password: 'password123') }

    context 'with a standard password' do
      it 'returns true when the password is correct' do
        expect(user.valid_password?('password123')).to be(true)
      end

      it 'returns false when the password is incorrect' do
        expect(user.valid_password?('password456')).to be(false)
      end
    end

    context 'with a password and legacy salt' do
      before do
        salt = SecureRandom.hex

        described_class.update(
          user.id,
          encrypted_password: BCrypt::Password.create("my password#{salt}", cost: 4),
          legacy_password_salt: salt
        )

        user.reload
      end

      it 'returns true when the password is correct' do
        expect(user.valid_password?('my password')).to be(true)
      end

      it 'returns false when the password is incorrect' do
        expect(user.valid_password?('password123')).to be(false)
      end
    end
  end

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
