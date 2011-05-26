module Gql

class Policy
  attr_reader :present_graph, :future_graph, :area, :present_area

  def initialize(present_graph, future_graph)
    @present_graph = present_graph
    @future_graph = future_graph
    @area = future_graph.area
    @present_area = present_graph.area
  end

  def goal(key)
    goals.detect{|g| g.key.to_sym == key.to_sym}
  end

  def goals
    @goals ||= ::PolicyGoal.allowed_policies.map(&:to_gql)
  end

  def inspect
    "<Gql::Policy #{present_graph.year} - #{future_graph.year}>"
  end

  def to_s
    inspect
  end
  
end

end
