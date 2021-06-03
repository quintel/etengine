# frozen_string_literal: true

module Qernel
  module Causality
    # Creates Reconciliation managers to compute time-resolved supply/demand
    # of carriers, as defined in ETSource.
    class ReconciliationWrapper
      def initialize(graph)
        @managers =
          Etsource::Reconciliation.map do |carrier, conf|
            create_manager(graph, carrier, conf)
          end
      end

      def setup_early
        @managers.each(&:initialize_adapters)
      end

      def setup
        @managers.each(&:setup_static)
      end

      def inject_values!
        # Calls setup_dynamic and inject on each manager in turn; this allows
        # each manager to refer to curves installed by earlier managers.
        @managers.each do |manager|
          manager.setup_dynamic
          manager.inject_values!
        end
      end

      # Internal: A hook which is called by Causality prior to the recalculation of the energy
      # graph.
      #
      # This is needed to allow electrolyzers to set the shares of some edges prior to the graph
      # being recalculated.
      def before_graph_recalculation
        @managers.each(&:before_graph_recalculation)
      end

      private

      def create_manager(graph, carrier, node_key_map)
        Qernel::Reconciliation::Manager.new(
          graph,
          carrier,
          node_key_map.transform_values do |typed_nodes|
            # Convert node keys to Node instances.
            typed_nodes.map { |key| graph.node(key) }
          end
        )
      end
    end
  end
end
