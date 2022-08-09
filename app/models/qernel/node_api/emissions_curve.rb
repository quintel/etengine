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
          if electricity_output_conversion.positive? && electricity_output_curve.any?
            primary_co2_emissions_curve_with_curve(electricity_output_curve)
          elsif electricity_input_conversion.positive?
            primary_co2_emissions_curve_with_curve(electricity_input_curve)
          else
            []
          end
        end
      end

      private

      def primary_co2_emissions_curve_with_curve(curve)
        return [] if demand.zero? || curve.empty?

        sum = curve.sum
        co2 = primary_co2_emission

        return [] if sum.zero?

        curve.map do |value|
          co2 * (value / sum)
        end
      end

      # def primary_co2_emissions_curve_with_conversion(curve, electricity_conversion)
      #   return [0.0] * 8760 if demand.zero? || !electricity_conversion.positive? || curve.empty?

      #   co2_per_mwh = primary_co2_emission / demand * MJ_PER_MWH

      #   curve.map do |electricity_in_hour|
      #     # Convert the electricity output for the current hour (MWh) to the equivalent
      #     # demand (MWh) on the node
      #     demand_in_hour = electricity_in_hour / electricity_conversion

      #     # Multiply the demand (in MWh) by the CO2 emissions per MWh to get the
      #     # amount of primary CO2 emission in this hour.
      #     demand_in_hour * co2_per_mwh
      #   end
      # end
    end
  end
end
