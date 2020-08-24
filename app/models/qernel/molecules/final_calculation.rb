# frozen_string_literal: true

module Qernel
  module Molecules
    # Calculates a molecule graph by setting values on a sparse molecule graph based on those in the
    # energy graph, then calculates the molecule graph.
    class FinalCalculation
      def initialize(energy_graph, molecule_graph)
        @energy_graph = energy_graph
        @molecule_graph = molecule_graph
      end

      # Public: Run the calculation of the molecule graph.
      def run
        Etsource::Molecules.from_energy_keys.each do |node_key|
          molecule_node = @molecule_graph.node(node_key)
          conversion    = molecule_node.from_energy
          energy_node   = @energy_graph.node(conversion.source)

          molecule_node.demand = Connection.demand(energy_node, conversion)
        end

        @molecule_graph.calculate
        @molecule_graph
      end

      private

      def create_molecule_graph
        graph = Etsource::Loader.instance.molecule_graph.tap
        graph.dataset = @energy_graph.dataset
        graph
      end
    end
  end
end
