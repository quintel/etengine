# frozen_string_literal: true

RSpec.describe User do
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
end
