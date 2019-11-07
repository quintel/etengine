# frozen_string_literal: true

module Api
  module V3
    # Creates CSV rows describing hydrogen production.
    class ReconciliationCSVPresenter
      # Provides support for multiple carriers in the presenter.
      class Adapter
        def initialize(carrier)
          @carrier = carrier.to_sym
        end

        def supported?(graph)
          graph.plugin(:time_resolve) &&
            Etsource::Reconciliation.supported_carrier?(@carrier)
        end

        def converters(graph)
          graph.converters.select(&@carrier)
        end

        def converter_curve(converter, direction)
          converter.converter_api.public_send("#{@carrier}_#{direction}_curve")
        end

        def converter_config(converter)
          converter.public_send(@carrier)
        end
      end

      def initialize(graph, carrier)
        @graph = graph
        @adapter = Adapter.new(carrier)
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

        [*producer_columns, *consumer_columns].transpose
      end

      private

      # Internal: Data about hydrogen production.
      def producer_columns
        converters_of_type(:producer, :import, :storage).map do |converter|
          column_from_converter(converter, :output)
        end
      end

      # Internal: Data about consumption production.
      def consumer_columns
        converters_of_type(:consumer, :export, :storage).map do |converter|
          column_from_converter(converter, :input)
        end
      end

      # Internal: Creates a column representing data for a converter in a
      # direction.
      def column_from_converter(converter, direction)
        loads =
          @adapter.converter_curve(converter, direction).map { |v| v.round(2) }

        ["#{converter.key}.#{direction}", *loads]
      end

      def converters_of_type(*types)
        types.flat_map { |type| converters[type] }.compact.sort_by(&:key)
      end

      def converters
        @converters ||=
          @adapter.converters(@graph)
            .each_with_object({}) do |converter, data|
              config = @adapter.converter_config(converter)

              next unless config

              data[config.type] ||= []
              data[config.type].push(converter)
            end
      end
    end
  end
end
