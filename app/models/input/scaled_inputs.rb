class Input
  # An Input::Cache-compatible class which takes the cached values and scaled
  # min, max, and default values to fit a scenario which is scaled by using
  # a scaler.
  class ScaledInputs
    # Public: Creates a ScaledInputs class, using the given Input::Cache as a
    # source for the original input values.
    def initialize(cache, gql)
      @cache = cache
      @gql   = gql
    end

    # Public: Retrieves the hash containing all of the scaled input attributes.
    #
    # See Input::Cache#read
    #
    # scenario - A scenario with an area code and end year.
    # input    - The input whose values are to be retrieved.
    #
    # Returns a hash.
    def read(scenario, input)
      values = @cache.send(:values_for, input, @gql)

      Scaler.new(input, scenario.scaler, values).scale
    end
  end # ScaledInputs
end
