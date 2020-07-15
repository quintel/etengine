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

      delegate(
        :carriers,
        :use_nodes,
        :sector_nodes,
        :group_nodes,
        :nodes,
        :group_edges,
        to: :energy_graph_helper
      )
    end
  end
end
