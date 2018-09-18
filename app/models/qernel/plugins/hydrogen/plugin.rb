module Qernel::Plugins
  module Hydrogen
    class Plugin
      Context = Struct.new(:dataset, :plugin, :graph)

      def initialize(graph)
        @graph = graph

        @context = Context.new(
          Atlas::Dataset.find(graph.area.area_code),
          self,
          graph
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

      # Public: Sets up and returns the time-resolved hydrogen calculator.
      # Memoizes after the first call.
      #
      # Returns a Hydrogen::Calculator.
      def calculator
        # @calculator ||= Calculator.new(total_demand_curve, total_supply_curve)
        @calculator ||= Calculator.new(
          Helper.total_demand_curve(self),
          Helper.total_supply_curve(self)
        )
      end

      # Internal: Takes loads and costs from the calculated Merit order, and
      # installs them on the appropriate converters in the graph. The updated
      # values will be used in the recalculated graph.
      #
      # Returns nothing.
      def inject_values!
        each_adapter { |adapter| adapter.inject!(calculator) }
        nil
      end

      # Public: Returns an array of all adapters of the given type.
      def adapter_group(type)
        adapters[type] || []
      end

      private

      # Internal: Creates and memoizes all adapters.
      def adapters
        # TODO Memoize list of nodes, as we do with Merit.
        @adapters ||= Atlas::Node.all
          .select(&:hydrogen)
          .group_by { |node| node.hydrogen.type }
          .transform_values do |nodes|
            nodes.map do |node|
              Adapter.adapter_for(@graph.converter(node.key), @context)
            end
          end
      end

      # Internal: Triggers the adapters to determine their demand and curve at the
      # right time in the setup.
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
