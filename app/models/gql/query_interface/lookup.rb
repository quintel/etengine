# frozen_string_literal: true

module Gql
  class QueryInterface
    # Provides helpers for looking up values from the scenario and graph.
    module Lookup
      def update_object
        @update_object
      end

      def update_object=(object)
        @update_object = object
      end

      def update_collection
        @update_collection
      end

      def update_collection=(col)
        @update_collection = col
      end

      def big_decimal(n)
        BigDecimal(n, exception: false) || n.to_f
      end

      def scenario
        @gql.scenario
      end

      def present?
        graph.present?
      end

      # @param [String] Graph API Method.
      # @return [Float]
      #
      def graph_query(key)
        key.nil? ? graph : graph.query(key)
      end

      # @param [String] Area attribute. E.g. areable_land
      # @return [Float]
      #
      def area(key)
        graph.area.send(key)
      end

      def all_nodes
        graph.nodes
      end

      # @param [String] Carrier key
      # @return [Carrier]
      #
      def carriers(keys)
        GraphHelper.carriers(graph, keys)
      end

      # @param [String,Array] Use keys
      # @return [Node]
      #
      def use_nodes(keys)
        GraphHelper.use_nodes(graph, keys)
      end

      # @param [String,Array] Sector keys
      # @return [Node]
      #
      def sector_nodes(keys)
        GraphHelper.sector_nodes(graph, keys)
      end

      # @param [String,Array] Group keys
      # @return [Node]
      #
      def group_nodes(keys)
        GraphHelper.group_nodes(graph, keys)
      end

      # @param [String] Node keys
      # @return [Node]
      #
      def nodes(keys)
        GraphHelper.nodes(graph, keys)
      end

      # @param [String,Array] Group keys
      # @return [Array<Edge>]
      #
      def group_edges(keys)
        GraphHelper.group_edges(graph, keys)
      end
    end
  end
end
