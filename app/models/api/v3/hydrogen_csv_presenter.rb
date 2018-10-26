module Api
  module V3
    # Creates CSV rows describing hydrogen production.
    class HydrogenCSVPresenter
      def initialize(graph)
        @graph = graph
      end

      # Public: Creates an array of rows for a CSV file containing the loads of
      # hydrogen producers and consumers.
      #
      # Returns an array of arrays.
      def to_csv_rows
        # Empty CSV if time-resolved calculations are not enabled.
        unless @graph.plugin(:time_resolve)&.hydrogen
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
        loads = converter.converter_api
          .public_send("hydrogen_#{direction}_curve").map { |val| val.round(2) }

        ["#{converter.key}.#{direction}", *loads]
      end

      def converters_of_type(*types)
        types.flat_map { |type| converters[type] }.sort_by(&:key)
      end

      def converters
        @converters ||= @graph.converters.select(&:hydrogen)
          .each_with_object({}) do |converter, data|
            next unless converter.hydrogen

            data[converter.hydrogen.type] ||= []
            data[converter.hydrogen.type].push(converter)
          end
      end
    end
  end
end
