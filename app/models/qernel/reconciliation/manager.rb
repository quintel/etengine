module Qernel
  module Reconciliation
    class Manager
      def initialize(graph, carrier_name, nodes)
        @graph = graph
        @nodes = nodes

        @context = Context.new(
          Atlas::Dataset.find(graph.area.area_code),
          self,
          graph,
          carrier_name
        )
      end

      # Public: Triggers the adapters whose demands are static.
      def setup_static
        setup_adapters(phase: :static)
      end

      # Public: Triggers the adapters whose demands are dynamic and depend on
      # Merit.
      def setup_dynamic
        setup_adapters(phase: :dynamic)
        setup_adapters(phase: :final)
      end

      # Public: Sets up and returns the time-resolved reconciliation calculator.
      # Memoizes after the first call.
      #
      # Returns a Reconciliation::Calculator.
      def calculator
        @calculator ||= Calculator.new(
          Helper.total_demand_curve(self),
          Helper.total_supply_curve(self)
        )
      end

      def curves
        @curves ||= Curves.new(@graph)
      end

      # Internal: Takes loads and costs from the calculated Merit order, and
      # installs them on the appropriate nodes in the graph. The updated
      # values will be used in the recalculated graph.
      #
      # Returns nothing.
      def inject_values!
        each_adapter { |adapter| adapter.inject!(calculator) }
        nil
      end

      # Public: Returns an array of all adapters of the given type which have
      # non-zero demand.
      def installed_adapters_of_type(type)
        (adapters[type] || []).select { |a| a.carrier_demand.positive? }
      end

      private

      # Internal: Creates and memoizes all adapters.
      def adapters
        @adapters ||=
          @nodes.transform_values do |convs|
            convs.map { |conv| Adapter.adapter_for(conv, @context) }
          end
      end

      # Internal: Triggers the adapters to determine their demand and curve at
      # the right time in the setup.
      #
      # phase - Symbol telling the plugin the current phase of the setup:
      #        :static (before Merit), :dynamic (after Merit), or :final
      #        (immediately after :dynamic).
      #
      # Returns nothing.
      def setup_adapters(phase:)
        each_adapter { |adapter| adapter.setup(phase: phase) }
      end

      # Internal: Iterates through each adapter.
      def each_adapter
        return enum_for(:each_adapter) unless block_given?

        adapters.values.flatten.each { |adapter| yield(adapter) }
      end
    end
  end
end
