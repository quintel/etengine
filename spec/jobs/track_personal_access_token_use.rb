# frozen_string_literal: true

RSpec.describe TrackPersonalAccessTokenUse, type: :job do
  context 'when Settings.etmodel_uri is set' do
    let(:user) { create(:user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id) }

    let(:personal_token) do
      PersonalAccessToken.create!(oauth_access_token: access_token, name: 'Test', user:)
    end

    context 'when the token is a personal access token' do
      before do
        personal_token.update!(last_used_at: 1.day.ago)
      end

      it 'updates the last_used_at attribute' do
        was = personal_token.last_used_at
        now = Time.now.utc

        expect { described_class.perform_now(access_token.id, now) }
          .to change { personal_token.reload.last_used_at }.from(was).to(now)
      end
    end

    context 'when the token has never been used' do
      before do
        personal_token.update!(last_used_at: nil)
      end

      it 'updates the last_used_at attribute' do
        now = Time.now.utc

        expect { described_class.perform_now(access_token.id, now) }
          .to change { personal_token.reload.last_used_at }.from(nil).to(now)
      end
    end

    context 'when the token is not a personal access token' do
      before do
        personal_token.destroy!
      end

      it 'does not raise an error' do
        expect { described_class.perform_now(access_token.id, Time.now.utc) }.not_to raise_error
      end
    end

    context 'when the token last use is more recent than the given time' do
      before do
        personal_token.update!(last_used_at: was)
      end

      let(:was) { 1.hour.ago }

      it 'does not update the last_used_at attribute' do
        expect { described_class.perform_now(access_token.id, 1.day.ago) }
          .not_to change { personal_token.reload.last_used_at }.from(was)
      end
    end
  end
end
