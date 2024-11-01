FactoryBot.define do
  factory :user do
    name { 'John Doe' }
    sequence(:email) { |n| "hello.#{n}@quintel.com" }
    roles { %w[user] }
    sequence(:id) { |n| n }

    initialize_with do
      User.new(name: name).tap do |user|
        user.identity_user = Identity::User.new(id: id, name: name, email: email, roles: roles)
      end
    end
  end

  factory :admin, parent: :user do
    roles { %w[user admin] }
  end
end
