# frozen_string_literal: true

FactoryBot.define do
  factory :personal_access_token do
    name { 'My Personal Access Token' }
    oauth_access_token { create(:access_token_read, resource_owner_id: user.id) }
    user { create(:user) }
  end
end
