FactoryGirl.define do
  factory :input do
    sequence(:lookup_id)
    key { "input-#{ lookup_id }" }
    factor 1
    min_value 0
    max_value 100
    start_value 10
  end

  factory :gql_input, parent: :input do
    start_value_gql 'present:2 * 4'
    min_value_gql   'present:2 * 2'
    max_value_gql   'present:2 * 8'
  end

  factory :static_input, parent: :input do
    start_value 0
    min_value   0
    max_value 100
  end
end
