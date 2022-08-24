# frozen_string_literal: true

# Useful helper methods for the nodes pages.
module NodesHelper
  # Queries a value on a node in both the present and future.
  def node_query_value(node, attribute)
    func = node.graph.name == :molecules ? 'MV' : 'V'
    gql_query("#{func}(#{node.key}, #{attribute})").results
  end

  def graph_unit(graph)
    graph.molecules? ? 'kg' : 'MJ'
  end

  def energy_flow_arrow
    # rubocop:disable Rails/OutputSafety
    <<~SVG.html_safe
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M9.707 14.707a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 1.414L7.414 9H15a1 1 0 110 2H7.414l2.293 2.293a1 1 0 010 1.414z" clip-rule="evenodd" />
      </svg>
    SVG
    # rubocop:enable Rails/OutputSafety
  end
end
