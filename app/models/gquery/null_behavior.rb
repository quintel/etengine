class Gquery
  # Module which adds no extra pre- or post-processing behavior when executing
  # an gquery that uses the behavior.
  module NullBehavior
    module_function

    def period_supported?(_period)
      true
    end

    def process_result(result)
      result
    end

    def fallback_value
      nil
    end
  end
end
