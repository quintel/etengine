# frozen_string_literal: true

module Api
  module V3
    # Creates CSV rows describing merit order production and consumption.
    class MeritCSVPresenter < CurvesCSVPresenter
      # Selects extra nodes to be included in or excluded from the CSV,
      # based on groups assigned to nodes.
      class NodeCustomisation
        def initialize(include_group = nil, exclude_group = nil)
          @include_group = include_group
          @exclude_group = exclude_group
        end

        def customise_producers(nodes, graph, adapter)
          (nodes + includes(graph, adapter, :output)) - excludes(graph)
        end

        def customise_consumers(nodes, graph, adapter)
          (nodes + includes(graph, adapter, :input)) - excludes(graph)
        end

        private

        # Public: Given a graph, returns a list of all nodes which should
        # be excluded from the CSV.
        def excludes(graph)
          @exclude_group ? graph.group_nodes(@exclude_group) : []
        end

        # Internal: Given a graph, returns a list of all nodes which should
        # be included in the CSV.
        def includes(graph, adapter, direction)
          return [] unless @include_group

          graph.group_nodes(@include_group).select do |conv|
            adapter.node_curve(conv, direction)&.any?
          end
        end
      end

      def initialize(graph, carrier, attribute = carrier, conv_cust = nil)
        super(graph, carrier, attribute)
        @node_customisation = conv_cust || NodeCustomisation.new
      end

      private

      def producers
        @node_customisation.customise_producers(
          super,
          @graph,
          @adapter
        ).sort_by(&:key)
      end

      def consumers
        @node_customisation.customise_consumers(
          super,
          @graph,
          @adapter
        ).sort_by(&:key)
      end

      def producer_types
        %i[producer flex]
      end

      def consumer_types
        %i[consumer flex]
      end

      def extra_columns
        [deficit_column]
      end

      def deficit_column
        production = Merit::CurveTools.add_curves(producers.map do |prod|
          @adapter.node_curve(prod, :output)
        end)

        consumption = Merit::CurveTools.add_curves(consumers.map do |cons|
          @adapter.node_curve(cons, :input)
        end)

        deficit =
          consumption.map.with_index do |amount, index|
            (amount - production[index]).round(4)
          end

        ['deficit', *deficit]
      end
    end
  end
end
