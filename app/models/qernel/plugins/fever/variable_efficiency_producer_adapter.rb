# frozen_string_literal: true

module Qernel::Plugins
  module Fever
    class VariableEfficiencyProducerAdapter < ProducerAdapter
      def inject!
        converter = @converter.converter

        based_on       = converter.input(@config.efficiency_based_on)
        balanced_with  = converter.input(@config.efficiency_balanced_with)
        combined_share = based_on[:conversion] + balanced_with[:conversion]

        super

        efficiency = 1 / load_adjusted_input_efficiency

        based_on[:conversion]      = efficiency * combined_share
        balanced_with[:conversion] = (1.0 - efficiency) * combined_share
      end

      private

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
    end
  end
end
