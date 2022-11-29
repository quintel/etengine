FactoryBot.define do
  factory :user do
    name { 'John Doe' }
    sequence(:email) { |n| "hello.#{n}@quintel.com" }
    password { 'password' }
  end

  factory :admin, parent: :user do
    admin { true }
  end
end
