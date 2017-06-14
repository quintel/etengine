class Input
  # Public: Given a hash of input values from a cache, scaled the values to be
  # appropriate for the size of the region.
  #
  # Dynamic input values are not scaled, since the graph should take care of
  # this automatically.
  #
  # Returns a hash of values.
  Scaler = lambda do |input, scaler, values|
    if ScenarioScaling.scale_input?(input) && scaler
      scaled = { step: scaler.input_step(values[:step]) }

      scaled[:min] = scaler.scale(values[:min]) unless input.min_value_gql
      scaled[:max] = scaler.scale(values[:max]) unless input.max_value_gql

      unless input.start_value_gql
        scaled[:default] = scaler.scale(values[:default])
      end

      values.merge(scaled)
    else
      values
    end
  end
end
