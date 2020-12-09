# frozen_string_literal: true

module CurveHandler
  # A base class which receives an uploaded user curve, and asserts that the curve is valid.
  class Generic
    attr_reader :errors, :error_keys

    MESSAGES = {
      illegal_value: 'Curve must only contain numeric values',
      not_a_curve: <<-MSG.squish,
        Curve must be a CSV file containing 8760 numeric values, one for each hour in a typical
        year
      MSG
      wrong_length: 'Curve must have 8760 numeric values, one for each hour in a typical year'
    }.freeze

    # Public: Returns the presenter class used to return data about the curve through the JSON API.
    def self.presenter
      Api::V3::CustomCurvePresenter
    end

    # Public: Takes a CSV file as a raw string, converts each line to a float and returns a
    # sanitizer.
    def self.from_string(string)
      string = string.force_encoding('UTF-8').delete_prefix("\xEF\xBB\xBF")

      # Match the first 1kb rather than the first line, to prevent DoS by uploading an extremely
      # large file with no newline.
      if string[0..1024].match?(/price/i)
        from_table_csv(string)
      else
        new(CSV.parse(string, converters: :float).flatten.compact)
      end
    rescue CSV::MalformedCSVError
      new(nil)
    end

    # Internal: When given a CSV with "Time" and "Price" headers, parses the file returning only the
    # price data.
    def self.from_table_csv(string)
      # Parse without nodes, as parsing with `:float` turns out to be extremely slow when given this
      # type of file.
      table = CSV.parse(string, converters: nil, headers: true)
      col = table.headers.find { |header| header.match(/price/i) }

      new(table[col].map do |value|
        CSV::Converters[:float].call(value)
      end)
    end

    private_class_method :from_table_csv

    # Create a new Sanitizer with an unsafe curve.
    #
    # curve - The curve whose values should be sanitized.
    def initialize(curve)
      @curve = curve
      @errors = []
      @error_keys = []
    end

    # Public: Provided the curve contains valid data, creates a sanitized version of the curve which
    # may be used in the calculation.
    #
    # Returns an array.
    def sanitized_curve
      valid? ? @curve : nil
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
