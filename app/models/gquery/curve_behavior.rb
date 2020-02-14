class Gquery
  # Module used by gquries which result a curve. These only return values for
  # the future, and truncate each value in the curve to reduce the amount of
  # data sent to the client.
  module CurveBehavior
    # If a curve has `NO_TRUNCATE_THRESHOLD` values between 0 and 1 on the first
    # day of each month, the values in the curve will not be truncated to
    # integers.
    NO_TRUNCATE_THRESHOLD = 12

    module_function

    def period_supported?(period)
      period == :future
    end

    def process_result(result)
      if truncate?(result, 300)
        result.map(&:truncate)
      else
        # Ruby 2.6: mult + truncate + to_f + div is faster than Float#round(4).
        result.map { |val| (val * 1000).truncate.to_f / 1000 }
      end
    end

    def fallback_value
      []
    end

    # Internal: Determines if the values in a curve should be truncated to whole
    # integers.
    #
    # Scan the first day of every second month (trusting that these days are
    # representative of the rest of the month). If the total number of values
    # greater than 0 -- but less than 300 - exceeds a threshold, the curve
    # should not be truncated.
    def truncate?(result, upper_value)
      count = 0
      per_window = result.length / 6
      per_day = result.length / 365

      return false if per_window.zero? || per_day < 1

      6.times do |month|
        start = month * per_window

        result[start..(start + per_day)].each do |val|
          val = val.abs
          count += 1 if val.positive? && val.abs < upper_value
        end
      end

      count < NO_TRUNCATE_THRESHOLD
    end
  end
end
