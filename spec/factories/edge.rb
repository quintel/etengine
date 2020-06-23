FactoryBot.define do
  factory :edge do
    parent_id 2#  {|parent| parent.association(:node) }
    node_id 3#  {|child| child.association(:node) }
    carrier_id 3
    edge_type 1
    excel_id 1
  end
end

