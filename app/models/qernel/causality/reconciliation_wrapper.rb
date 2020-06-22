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
