FactoryGirl.define do
  factory :gquery do
    sequence(:key) { |n| "key_#{n}" }
    query "a_gql_query"
  end
end
