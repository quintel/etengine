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

      def all_energy_nodes
        graph.nodes
      end

      def all_molecule_nodes
        molecules.nodes
      end

      delegate :nodes, to: :energy_graph_helper

      def energy_sector_nodes(keys)
        energy_graph_helper.sector_nodes(keys)
      end

      def molecule_sector_nodes(keys)
        molecule_graph_helper.sector_nodes(keys)
      end

      def energy_use_nodes(keys)
        energy_graph_helper.use_nodes(keys)
      end

      def group_energy_nodes(keys)
        energy_graph_helper.group_nodes(keys)
      end

      def group_molecule_nodes(keys)
        molecule_graph_helper.group_nodes(keys)
      end

      def group_energy_edges(keys)
        energy_graph_helper.group_nodes(keys)
      end

      def group_molecule_edges(keys)
        molecule_graph_helper.group_nodes(keys)
      end

      def energy_carriers(keys)
        energy_graph_helper.carriers(keys)
      end

      def molecule_carriers(keys)
        molecule_graph_helper.carriers(keys)
      end
    end
  end
end
