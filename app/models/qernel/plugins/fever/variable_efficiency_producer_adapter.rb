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
        1.0 - (based_on_slot[:conversion] + balanced_with_slot[:conversion])
      end

      # Internal: The input efficiency curve to be used by the producer.
      #
      # Returns an array.
      def input_efficiency
        base_eff = @converter.electricity_input_conversion

        temperature_curve.map do |val|
          case val
          when -Float::INFINITY...-10 then 1 / (base_eff * 2.0)
          when -10...0                then 1 / (base_eff * 1.6)
          when 0...10                 then 1 / (base_eff * 1.2)
          when 10...20                then 1 / (base_eff * 1.0)
          when 20...30                then 1 / (base_eff * 0.8)
          when 30..Float::INFINITY    then 1 / (base_eff * 0.6)
          end
        end
      end

      # Internal: The curve of air temperatures in the region.
      def temperature_curve
        Qernel::Plugins::TimeResolve.load_profile(@dataset, 'air_temperature')
      end

      def capacity
        heat_capacity =
          if @config.capacity.present?
            total_value { @config.capacity[@config.efficiency_based_on] }
          else
            total_value(:heat_output_capacity)
          end

        converter = @converter.converter

        # Producers with only two slots (the based_on and balanced_with) use the
        # full output capacity; others with more input slots must adjust for the
        # presence of the other inputs.
        return heat_capacity if converter.inputs.length < 3

        heat_capacity * combined_share
      end
    end
  end
end
