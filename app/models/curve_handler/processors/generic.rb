# frozen_string_literal: true

module CurveHandler
  module Processors
    # A base class which receives an uploaded user curve, and asserts that the curve is valid.
    class Generic
      attr_reader :errors, :error_keys

      MESSAGES = {
        illegal_value: 'Curve must only contain numeric values',
        too_many_columns: <<-MSG.squish,
          Curve must contain only a single numeric value on each line; multiple values separated
          by commas are not permitted
        MSG
        not_a_curve: <<-MSG.squish,
          Curve must be a file containing 8760 numeric values, one for each hour in a typical
          year
        MSG
        wrong_length: 'Curve must have 8760 numeric values, one for each hour in a typical year'
      }.freeze

      # Public: Returns the serializer class which converts the curve information to JSON.
      def self.serializer
        CustomCurveSerializer
      end

      def self.remove_bom(string)
        string.force_encoding('UTF-8').delete_prefix("\xEF\xBB\xBF")
      end

      # Public: Takes a CSV file as a raw string, converts each line to a float and returns a
      # sanitizer.
      def self.from_string(string)
        array = CSV.parse(remove_bom(string), converters: :float)

        # If any row has more than one value, the file probably contains commas. Allow those where
        # the comma was simply a trailing value after a valid number.
        if array.find { |row| row.length > 1 && !(row.length == 2 && row.last.nil?) }
          new(array)
        else
          new(array.flatten.compact)
        end
      rescue CSV::MalformedCSVError
        new(nil)
      end

      # Create a new Sanitizer with an unsafe curve.
      #
      # curve - The curve whose values should be sanitized.
      def initialize(curve)
        @curve = curve
        @errors = []
        @error_keys = []
      end

      # Public: Provided the curve contains valid data, creates a sanitized version of the curve
      # provided by the user.
      #
      # Returns an array.
      def sanitized_curve
        valid? ? @curve : nil
      end

      # Public: Returns the curve as it should be stored. May performs additional processing on the
      # `sanitized_curve` immediately prior to being stored.
      def curve_for_storage
        sanitized_curve
      end

      # Public: Determines if the curve provided by the user contains valid data allowing it to be
      # used as a price curve.
      #
      # Returns true or false.
      def valid?
        @errors = []

        unless @curve.is_a?(Array)
          add_error(:not_a_curve)
          return false
        end

        if @curve.first.is_a?(Array)
          add_error(:too_many_columns)
          return false
        end

        add_error(:wrong_length) if @curve.length != 8760
        add_error(:illegal_value) if @curve.any? { |value| !value.is_a?(Numeric) }

        @errors.none?
      end

      def add_error(key)
        @errors.push(MESSAGES[key])
        @error_keys.push(key)
      end

      def inspect
        "#<#{self.class.name}>"
      end
    end
  end
end
