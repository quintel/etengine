FactoryBot.define do
  factory :node, class: 'Qernel::Node' do
    sequence(:id)
    graph_name { :energy }

    initialize_with { new(attributes) }
  end
end
