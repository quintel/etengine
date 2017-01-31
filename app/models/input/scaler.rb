class Input
  class Scaler
    def initialize(input, scaler, values)
      @input  = input
      @scaler = scaler
      @values = values
    end

    def scale
      if ScenarioScaling.scale_input?(@input) && @scaler
        scaled = { step: @scaler.input_step(@values[:step]) }

        unless @input.min_value_gql
          scaled[:min] = @scaler.scale(@values[:min])
        end

        unless @input.max_value_gql
          scaled[:max] = @scaler.scale(@values[:max])
        end

        unless @input.start_value_gql
          scaled[:default] = @scaler.scale(@values[:default])
        end

        @values.merge(scaled)
      else
        @values
      end
    end
  end
end
