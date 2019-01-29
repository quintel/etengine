class Gquery
  # Module used by gquries which result a curve. These only return values for
  # the future, and truncate each value in the curve to reduce the amount of
  # data sent to the client.
  module CurveBehavior
    module_function

    def period_supported?(period)
      period == :future
    end

    def process_result(result)
      result.map(&:truncate)
    end

    def fallback_value
      []
    end
  end
end
