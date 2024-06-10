FactoryBot.define do
  factory :user do
    name { 'John Doe' }
    sequence(:email) { |n| "hello.#{n}@quintel.com" }
    password { 'password' }

    trait :confirmed_at do
      confirmed_at { Time.current }
    end
  end

  factory :admin, parent: :user do
    admin { true }
  end
end
