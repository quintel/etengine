# frozen_string_literal: true

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

      Scaler.call(input, scenario.scaler, values)
    end

    # Public: Retrieves cached data for multiple inputs at once, with scaling applied.
    #
    # See Input::Cache#read_many
    #
    # scenario - A scenario with an area code and end year.
    # inputs   - Array of inputs whose values are to be retrieved.
    #
    # Returns a hash of { input_key => cached_data }
    def read_many(scenario, inputs)
      inputs.each_with_object({}) do |input, results|
        key = input.is_a?(Input) ? input.key : input.to_s
        values = @cache.send(:values_for, input, @gql)
        results[key] = Scaler.call(input, scenario.scaler, values)
      end
    end
  end
end
