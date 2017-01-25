class Input
  class Cache
    # Retrieves the hash containing all of the input attributes.
    #
    # If no values for the area and year are already cached, the entire input
    # collection values will be calculated and cached.
    #
    # @param [Scenario] scenario
    #   A scenario with an area code and end year.
    # @param [Input] input
    #   The input whose values are to be retrieved.
    #
    def read(scenario, input)
      cache_key = input_cache_key(scenario, input)

      Rails.cache.read(cache_key) ||
        ( warm_values_for(scenario) && Rails.cache.read(cache_key) )
    end

    #######
    private
    #######

    # Sets the hash containing all of the input attributes.
    #
    # @param [Scenario] scenario
    #   A scenario with an area code and end year.
    # @param [Input] input
    #   The input whose values are to be set.
    # @param [Hash{Symbol=>Numeric}] values
    #   Values for the input.
    #
    def set(scenario, input, values)
      Rails.cache.write(input_cache_key(scenario, input), values)
    end

    # Given a scenario, pre-calculates the values for each input using the
    # scenario area and end year, and stores them in memcache for fast
    # retrieval later.
    #
    # @param [Scenario] scenario
    #   A scenario with an area code and end year. All other attributes are
    #   ignored.
    #
    def warm_values_for(scenario)
      attributes = scenario.attributes.slice('area_code', 'end_year')
      gql        = Scenario.new(attributes).gql

      Input.all.each do |input|
        set(scenario, input, values_for(input, gql))
      end
    end

    # Returns the values which should be cached for an input.
    #
    # @param [Input] input
    #   The input whose values are to be cached.
    # @param [Gql::Gql] gql
    #   GQL instance for calculating values.
    #
    def values_for(input, gql)
      values = {
        min:      input.min_value_for(gql),
        max:      input.max_value_for(gql),
        default:  input.start_value_for(gql),
        label:    input.label_value_for(gql),
        disabled: input.disabled_in_current_area?(gql),
        step:     input.step_value
      }

      values = Scaler.new(input, scaler_for(gql), values).scale

      required_numerics = values.slice(:min, :max, :default).values

      if required_numerics.any? { |value| ! value.kind_of?(Numeric) }
        { disabled: true, error: 'Non-numeric GQL value' }
      else
        values
      end
    end

    def scaler_for(gql)
      if gql.scenario && Area.derived?(gql.scenario.area_code)
        ScenarioScaling.from_atlas_scaling(gql.scenario.area[:scaling])
      end
    end

    # Given a scenario, returns the key used to store cached minimum, maximum,
    # and start values.
    #
    # @param [Scenario] scenario
    #   The scenario containing an area code and end year.
    # @param [Input] input
    #   The input whose key you want.
    #
    def input_cache_key(scenario, input)
      area = scenario.area_code || :unknown
      year = scenario.end_year  || :unknown
      key  = input.kind_of?(Input) ? input.key : input

      "#{ area }.#{ year }.inputs.#{ key }.values"
    end
  end # Cache
end
