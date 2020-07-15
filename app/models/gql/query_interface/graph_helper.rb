# frozen_string_literal: true

module Gql
  class QueryInterface
    # Wraps a Qernel::Graph with a generic interface supporting queries from GQL functions.
    module GraphHelper
      module_function

      # Public: Retrieves a list of `Qernel::Carrier`s used by the graph.
      def carriers(graph, keys)
        call_graph(graph, :carrier, keys)
      end

      # Public: Returns all nodes whose "use" attribute matches at least one of the `keys`.
      def use_nodes(graph, keys)
        call_graph(graph, :use_nodes, keys)
      end

      # Public: Returns all nodes whose "sector" attribute matches at least one of the `keys`.
      def sector_nodes(graph, keys)
        call_graph(graph, :sector_nodes, keys)
      end

      # Public: Returns all nodes belonging to a group named by at least one of the `keys`.
      def group_nodes(graph, keys)
        call_graph(graph, :group_nodes, keys)
      end

      # Public: Returns all nodes matching the `keys`.
      def nodes(graph, keys)
        call_graph(graph, :node, keys)
      end

      # Public: Returns all edges belonging to a group named by at least one of the `keys`.
      def group_edges(graph, keys)
        call_graph(graph, :group_edges, keys)
      end

      def call_graph(graph, method, keys)
        result = if keys.is_a?(Array)
          keys.flat_map { |key| graph.public_send(method, key) }
        else
          Array(graph.public_send(method, keys))
        end

        result.compact!
        result
      end

      private_class_method :call_graph
    end
  end
end
