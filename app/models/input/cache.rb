class Input
  # Stores and retrieves input min, max, and start values.
  class Cache
    # Public: Retrieves the hash containing all of the input attributes.
    #
    # If no values for the area and year are already cached, the entire input
    # collection values will be calculated and cached.
    #
    # scenario - A scenario with an area code and end year.
    # input    - The input whose values are to be retrieved.
    #
    # Returns a hash of the input min, max, etc.
    def read(scenario, input)
      cache_key = input_cache_key(scenario, input)

      Rails.cache.read(cache_key) ||
        (warm_values_for(scenario) && Rails.cache.read(cache_key))
    end

    private

    # Internal: Sets the hash containing all of the input attributes.
    #
    # scenario - A scenario with an area code and end year.
    # input    - The input whose values are to be set.
    # values   - Values for the input in the form
    #            { min: Numeric, max: Numeric } etc
    #
    # Returns the values written.
    def set(scenario, input, values)
      Rails.cache.write(input_cache_key(scenario, input), values)
    end

    # Internal: Pre-calculates values for each input.
    #
    # scenario - A scenario with an area code and end year. All other attributes
    #            are ignored.
    #
    # Returns nothing.
    def warm_values_for(scenario)
      attributes = scenario.attributes.slice('area_code', 'end_year')
      gql        = Scenario.new(attributes).gql

      Input.all.each do |input|
        set(scenario, input, values_for(input, gql))
      end
    end

    # Internal: The values which will be cached for an input.
    #
    # input - The input whose values are to be cached.
    # gql - GQL instance for calculating values.
    #
    # Returns a hash of the input values.
    def values_for(input, gql)
      values = {
        min:      input.min_value_for(gql),
        max:      input.max_value_for(gql),
        default:  input.start_value_for(gql),
        label:    input.label_value_for(gql),
        disabled: input.disabled_in_current_area?(gql),
        step:     input.step_value
      }

      # TODO: Remove once adding a proper "permited_values" attribute.
      values[:min] = values[:min].map(&:to_s) if input.unit == 'enum'

      values = Scaler.call(input, scaler_for(gql), values)
      required_numerics = values.values_at(*input.required_numeric_attributes)

      if required_numerics.any? { |value| ! value.is_a?(Numeric) }
        { disabled: true, error: 'Non-numeric GQL value' }
      else
        values
      end
    end

    # Internal: The scaler for the given GQL, or nil if the scenario is not
    # scaled.
    def scaler_for(gql)
      if gql.scenario && Area.derived?(gql.scenario.area_code)
        ScenarioScaling.from_atlas_scaling(gql.scenario.area[:scaling])
      end
    end

    # Internal: Given a scenario, returns the key used to store cached minimum,
    # maximum, and start values.
    #
    # scenario - The scenario containing an area code and end year.
    # input    - The input whose key you want.
    #
    def input_cache_key(scenario, input)
      area = scenario.area_code || :unknown
      year = scenario.end_year  || :unknown
      key  = input.kind_of?(Input) ? input.key : input

      "#{ area }.#{ year }.inputs.#{ key }.values"
    end
  end # Cache
end
