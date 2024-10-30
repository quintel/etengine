
FactoryBot.define do
  factory :access_token, class: OpenStruct do
    resource_owner_id { nil }           # Expect this to be passed in
    sub { resource_owner_id.to_s }      # Uses `resource_owner_id` directly
    token { SecureRandom.hex(16) }      # Unique token string
    refresh_token { SecureRandom.hex(16) } # Optional, for token refreshing
    scopes { 'public' }                 # Set default scopes
    expires_in { 7200 }                 # Token expiration in seconds (e.g., 2 hours)
    created_at { Time.current }         # Creation time for the token

    initialize_with { new(attributes) }

    factory :access_token_read do
      scopes { 'public scenarios:read' }
    end

    factory :access_token_write do
      scopes { 'public scenarios:read scenarios:write' }
    end

    factory :access_token_delete do
      scopes { 'public scenarios:read scenarios:delete' }
    end
  end
end
