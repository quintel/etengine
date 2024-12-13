# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:id, 1000) { |n| n } # Start IDs at 1000 to avoid conflicts with potential seeds
    name { 'John Doe' }
    sequence(:email) { |n| "person#{n}@quintel.com" }
    roles { %w[user] }

    initialize_with do
      User.new(id:, name:).tap do |user|
        user.identity_user = Identity::User.new(id:, name:, email:, roles:)
      end
    end
  end

  factory :admin, parent: :user do
    roles { %w[user admin] }
  end
end
