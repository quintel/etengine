# frozen_string_literal: true

# Useful helper methods for the nodes pages.
module NodesHelper
  # Queries a value on a node in both the present and future.
  def node_query_value(node, attribute)
    func = node.graph.name == :molecules ? 'MV' : 'V'
    gql_query("#{func}(#{node.key}, #{attribute})").results
  end
end
