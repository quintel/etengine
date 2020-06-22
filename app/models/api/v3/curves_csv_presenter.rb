# frozen_string_literal: true

module Api
  module V3
    # The CSV contains the key of each node and the direction of energy
    # flow (input or output) and the hourly load in MWh.
    class CurvesCSVPresenter
      # Provides support for multiple carriers in the presenter.
      class Adapter
        attr_reader :attribute

        def initialize(carrier, attribute)
          @carrier = carrier.to_sym
          @attribute = attribute.to_sym
        end

        def supported?(graph)
          Qernel::Plugins::Causality.enabled?(graph)
        end

        def nodes(graph)
          graph.nodes.select(&@attribute)
        end

        def node_curve(node, direction)
          node.node_api.public_send("#{@carrier}_#{direction}_curve")
        end

        def node_config(node)
          node.public_send(@attribute)
        end
      end

      def self.time_column(year)
        # We don't model leap days: 1970 is a safe choice for accurate times in
        # the CSV.
        base_date = Time.utc(1970, 1, 1)

        ['Time'] +
          Array.new(8760) do |i|
            (base_date + i.hours).strftime("#{year}-%m-%d %R")
          end
      end

      def initialize(graph, carrier, attribute = carrier)
        @graph = graph
        @adapter = Adapter.new(carrier, attribute)
      end

      # Used as the name of the CSV file when sent to the user. Omit the file
      # extension.
      def filename
        @adapter.attribute
      end

      # Public: Creates an array of rows for a CSV file containing the loads of
      # hydrogen producers and consumers.
      #
      # Returns an array of arrays.
      def to_csv_rows
        # Empty CSV if time-resolved calculations are not enabled.
        unless @adapter.supported?(@graph)
          return [['Merit order and time-resolved calculation are not ' \
                   'enabled for this scenario']]
        end

        [
          self.class.time_column(@graph.year),
          *producer_columns,
          *consumer_columns,
          *extra_columns
        ].transpose
      end

      private

      def producer_columns
        producers.map { |node| column_from_node(node, :output) }
      end

      def consumer_columns
        consumers.map { |node| column_from_node(node, :input) }
      end

      def extra_columns
        []
      end

      def producers
        nodes_of_type(producer_types).select do |producer|
          @adapter.node_curve(producer, :output)&.any?
        end
      end

      def consumers
        nodes_of_type(consumer_types) do |consumer|
          @adapter.node_curve(consumer, :output)&.any?
        end
      end

      # Internal: Creates a column representing data for a node's energy
      # flows in a chosen direction.
      def column_from_node(node, direction)
        [
          "#{node.key}.#{direction}",
          *@adapter.node_curve(node, direction).map { |v| v.round(4) }
        ]
      end

      def nodes_of_type(types)
        @adapter.nodes(@graph)
          .select { |c| types.include?(@adapter.node_config(c).type) }
          .sort_by(&:key)
      end
    end
  end
end
