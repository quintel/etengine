# frozen_string_literal: true

FactoryBot.define do
  factory :access_token, class: 'Doorkeeper::AccessToken' do
    scopes { 'public' }
    sequence(:resource_owner_id) { |n| n }
  end

  factory :access_token_read, parent: :access_token do
    scopes { 'public scenarios:read' }
  end

  factory :access_token_write, parent: :access_token do
    scopes { 'public scenarios:read scenarios:write' }
  end

  factory :access_token_delete, parent: :access_token do
    scopes { 'public scenarios:read scenarios:delete' }
  end
end
