# frozen_string_literal: true

module Api
  module V3
    # The CSV contains the key of each converter and the direction of energy
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

        def converters(graph)
          graph.converters.select(&@attribute)
        end

        def converter_curve(converter, direction)
          converter.converter_api.public_send("#{@carrier}_#{direction}_curve")
        end

        def converter_config(converter)
          converter.public_send(@attribute)
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
          *consumer_columns
        ].transpose
      end

      private

      def producer_columns
        converters_of_type(*producer_types).map do |converter|
          column_from_converter(converter, :output)
        end
      end

      def consumer_columns
        converters_of_type(*consumer_types).map do |converter|
          column_from_converter(converter, :input)
        end
      end

      # Internal: Creates a column representing data for a converter's energy
      # flows in a chosen direction.
      def column_from_converter(converter, direction)
        [
          "#{converter.key}.#{direction}",
          *@adapter.converter_curve(converter, direction).map { |v| v.round(4) }
        ]
      end

      def converters_of_type(*types)
        @adapter.converters(@graph)
          .select { |c| types.include?(@adapter.converter_config(c).type) }
          .sort_by(&:key)
      end
    end
  end
end
