# frozen_string_literal: true

module Qernel::Plugins
  module Fever
    class VariableEfficiencyProducerAdapter < ProducerAdapter
      def inject!
        share = combined_share

        super

        load_efficiency = load_adjusted_input_efficiency

        unless load_efficiency.zero?
          efficiency = 1 / load_efficiency

          based_on_slot[:conversion]      = efficiency * share
          balanced_with_slot[:conversion] = (1.0 - efficiency) * share
        end
      end

      # Internal: Computes the actual efficiency of the heat pump over the year,
      # depending on when demand arose.
      #
      # Returns a numeric.
      def load_adjusted_input_efficiency
        producer = participant.producer
        lcurve   = producer.load_curve

        lcurve.map.with_index do |load, index|
          input = producer.input_at(index)
          input.zero? ? 0.0 : load / producer.input_at(index)
        end.sum / lcurve.length
      end

      # Internal: The slot whose efficiency varies depending on the temperature
      # curve.
      def based_on_slot
        @converter.converter.input(@config.efficiency_based_on)
      end

      # Internal: The slot whose conversion will be adjusted according to the
      # change in efficiency of the "based_on" slot.
      def balanced_with_slot
        @converter.converter.input(@config.efficiency_balanced_with)
      end

      private

      # Internal: The share of the two inputs.
      def combined_share
        1.0 - (based_on_slot.conversion + balanced_with_slot.conversion)
      end

      # Internal: The input efficiency curve to be used by the producer.
      #
      # Returns an array.
      def input_efficiency
        @input_efficiency ||= begin
          base_cop   = @config.base_cop
          per_degree = @config.cop_per_degree

          temperature_curve.map do |val|
            cop = base_cop + per_degree * val

            # Coefficient of performance must not drop below 1.0 (where there is
            # no "balanced_with" energy, and only "based_on" energy is used).
            cop < 1.0 ? 1.0 : cop
          end
        end
      end

      # Internal: The curve of air temperatures in the region.
      def temperature_curve
        Qernel::Plugins::TimeResolve.load_profile(@dataset, 'air_temperature')
      end

      def capacity
        return efficiency_based_capacity if @config.capacity.present?

        heat_capacity = total_value(:heat_output_capacity)
        converter = @converter.converter

        # Producers with only two slots (the based_on and balanced_with) use the
        # full output capacity; others with more input slots must adjust for the
        # presence of the other inputs.
        return heat_capacity if converter.inputs.length < 3

        heat_capacity * combined_share
      end

      # Internal: Producers with a "capacity" attribute assigned to the producer
      # have a fixed input capacity, and the output capacity is a function of
      # the input and the efficiency.
      #
      # Returns an array.
      def efficiency_based_capacity
        cop_cutoff = @config.cop_cutoff || 1.0

        input_cap = total_value do
          @config.capacity[@config.efficiency_based_on]
        end

        input_efficiency.map do |eff|
          eff < cop_cutoff ? 0.0 : input_cap * eff
        end
      end
    end
  end
end
