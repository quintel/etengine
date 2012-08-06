FactoryGirl.define do
  factory :input do
    key 'an_input'
    sequence(:lookup_id)
    factor 1
  end
end
