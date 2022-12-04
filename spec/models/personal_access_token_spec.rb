# frozen_string_literal: true

RSpec.describe PersonalAccessToken, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:oauth_access_token).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:name) }
end
