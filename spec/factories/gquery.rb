Factory.define :gquery do |f|
  f.sequence(:key) { |n| "key_#{n}" }
  f.query "a_gql_query"
end