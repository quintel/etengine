FactoryBot.define do
  factory :user do
    name { 'John Doe' }
    sequence(:email) { |n| "hello.#{n}@quintel.com" }
    roles { %w[user] }

    transient do
      identity_id { SecureRandom.uuid } # Unique id for Identity::User
      jwt_payload do
        {
          'sub' => identity_id,
          'user' => { 'name' => name }
        }
      end
    end

    initialize_with do
      User.new(name: name).tap do |user|
        user.identity_user = Identity::User.new(id: identity_id, name: name, email: email, roles: roles)
      end
    end
  end

  factory :admin, parent: :user do
    roles { %w[user admin] }
  end
end
