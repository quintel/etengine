# frozen_string_literal: true

module CurveHandler
  module Processors
    # An extension to the Generic handler which reduces the precision of each point in the curve to
    # two decimal places.
    class Price < Generic
      def self.serializer
        CustomPriceCurveSerializer
      end

      # Public: Takes a CSV file as a raw string, converts each line to a float and returns a
      # sanitizer.
      def self.from_string(string)
        string = remove_bom(string)

        # Match the first 1kb rather than the first line, to prevent DoS by uploading an extremely
        # large file with no newline.
        if string[0..1024].match?(/price/i)
          from_table_csv(string)
        else
          super
        end
      rescue CSV::MalformedCSVError
        new(nil)
      end

      # Internal: When given a CSV with "Time" and "Price" headers, parses the file returning only
      # the price data.
      def self.from_table_csv(string)
        # Parse without nodes, as parsing with `:float` turns out to be extremely slow when given
        # this type of file.
        table = CSV.parse(string, converters: nil, headers: true)
        col = table.headers.find { |header| header.match(/price/i) }

        new(table[col].map do |value|
          CSV::Converters[:float].call(value)
        end)
      end

      private_class_method :from_table_csv

      def sanitized_curve
        return nil unless valid?

        @curve.map do |value|
          value < 0.0 ? 0.0 : value.round(2)
        end
      end
    end
  end
end
