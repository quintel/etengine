# frozen_string_literal: true

module Qernel
  module NodeApi
    # Generates an emissions curve based on the electricity output.
    module EmissionsCurve
      # Generates a curve describing the primary CO2 emissions of the node.
      #
      # This requires that the node has an electricity output, and that it participates as a
      # producer in the electricity merit order.
      #
      # Returns a curve containing numeric values in kg.
      def primary_co2_emission_curve
        fetch(:primary_co2_emission_curve) do
          emissions_curve_with_curve(detect_emission_curve_profile_base, primary_co2_emission)
        end
      end

      def primary_captured_co2_emission_curve
        fetch(:primary_captured_co2_emission_curve) do
          emissions_curve_with_curve(
            detect_emission_curve_profile_base,
            primary_captured_co2_emission
          )
        end
      end

      private

      def detect_emission_curve_profile_base
        if electricity_output_conversion.positive? && electricity_output_curve.any?
          electricity_output_curve
        elsif electricity_input_conversion.positive?
          electricity_input_curve
        end
      end

      def emissions_curve_with_curve(curve, base_value)
        return [] if demand.zero? || curve.nil? || curve.empty?

        sum = curve.sum

        return [] if sum.zero?

        curve.map do |value|
          base_value * (value / sum)
        end
      end
    end
  end
end
