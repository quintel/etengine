# frozen_string_literal: true

module Gql
  class QueryInterface
    # Wraps a Qernel::Graph with a generic interface supporting queries from GQL functions.
    class GraphHelper
      attr_reader :graph

      def initialize(graph)
        @graph = graph
      end

      # Public: Retrieves a list of `Qernel::Carrier`s used by the graph.
      def carriers(keys)
        call_graph(:carrier, keys)
      end

      # Public: Returns all nodes whose "use" attribute matches at least one of the `keys`.
      def use_nodes(keys)
        call_graph(:use_nodes, keys)
      end

      # Public: Returns all nodes whose "sector" attribute matches at least one of the `keys`.
      def sector_nodes(keys)
        call_graph(:sector_nodes, keys)
      end

      # Public: Returns all nodes belonging to a group named by at least one of the `keys`.
      def group_nodes(keys)
        call_graph(:group_nodes, keys)
      end

      # Public: Returns all nodes matching the `keys`.
      def nodes(keys)
        call_graph(:node, keys)
      end

      # Public: Returns all edges belonging to a group named by at least one of the `keys`.
      def group_edges(keys)
        call_graph(:group_edges, keys)
      end

      private

      def call_graph(method, keys)
        result = if keys.is_a?(Array)
          keys.flat_map { |key| @graph.public_send(method, key) }
        else
          Array(@graph.public_send(method, keys))
        end

        result.compact!
        result
      end
    end
  end
end
