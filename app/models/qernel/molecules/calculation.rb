# frozen_string_literal: true

module Qernel
  module Molecules
    # Calculates a molecule graph by setting values on a sparse molecule graph based on those in the
    # energy graph, then calculates the molecule graph. Finally, it sets some demands on the energy
    # graph prior to the calculation of Causality.
    class Calculation < FinalCalculation
      def initialize(*)
        super
        @cached_demands = {}
      end

      def run
        super

        Etsource::Molecules.from_molecules_keys.each do |node_key|
          energy_node   = @energy_graph.node(node_key)
          conversion    = energy_node.from_molecules
          molecule_node = @molecule_graph.node(conversion.source)

          demand = Connection.demand(molecule_node, conversion)

          @cached_demands[node_key] = demand
          energy_node.demand = demand
        end
      end

      # Public: Sets cached demands on each node.
      #
      # Causality restored the graph dataset to a snapshot created prior to Molecules running. This
      # means demand set in #run (for use in Causality) will have been removed from the dataset.
      # reinstall_demands sets the demands again, so that they are fully accounted for in the second
      # calculation of the energy graph.
      #
      # Returns nothing.
      def reinstall_demands
        @cached_demands.each do |key, demand|
          @energy_graph.node(key).demand = demand
        end
      end
    end
  end
end
