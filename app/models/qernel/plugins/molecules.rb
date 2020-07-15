# frozen_string_literal: true

module Qernel
  module Plugins
    # Simple implementation of a molecules graph. Each energy graph has a Molecules plugin which
    # holds the molecules graph, calculation of which is triggered after the first calculation of
    # the energy graph.
    class Molecules
      include Plugin

      def self.enabled?(graph)
        graph.energy?
      end

      # Public: Returns the molecules Qernel::Graph.
      def molecule_graph
        @molecule_graph ||= Etsource::Loader.instance.molecule_graph.tap do |mg|
          mg.dataset = @graph.dataset
          mg.calculate
        end
      end
    end
  end
end
