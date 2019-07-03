# frozen_string_literal: true

module Api
  # Receives an uploaded curve from a user, asserts that the curve is valid,
  # then reduces each value to two-decimal places.
  class PriceCurveSanitizer
    attr_reader :errors, :error_keys

    MESSAGES = {
      not_a_curve:
        'Curve must be a CSV file containing 8760 numeric values, one for ' \
        'each hour in a typical year',
      wrong_length:
        'Curve must have 8760 numeric values, one for each hour in a typical ' \
        'year',
      illegal_value:
        'Curve must only contain numeric values'
    }.freeze

    # Public: Takes a CSV file as a raw string, converts each line to a float
    # and returns a sanitizer.
    def self.from_string(string)
      new(CSV.parse(string, converters: :float).flatten.compact)
    rescue CSV::MalformedCSVError
      new(nil)
    end

    # Create a new Sanitizer with an unsafe curve.
    #
    # curve - The curve whose values should be sanitized.
    #
    def initialize(curve)
      @curve = curve
      @errors = []
      @error_keys = []
    end

    # Public: Provided the curve contains valid data, creates a sanitized
    # version of the curve which may be used in the calculation.
    #
    # Returns an array.
    def sanitized_curve
      valid? ? @curve.map { |value| value.round(2) } : nil
    end

    # Public: Determines if the curve provided by the user contains valid data
    # allowing it to be used as a price curve.
    #
    # Returns true or false.
    def valid?
      @errors = []

      unless @curve.is_a?(Array)
        add_error(:not_a_curve)
        return false
      end

      add_error(:wrong_length) if @curve.length != 8760

      if @curve.any? { |value| !value.is_a?(Numeric) }
        add_error(:illegal_value)
      end

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
