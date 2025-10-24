# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Implements behaviour specific to the power2heat (pumps) that
    # are dependent on outside temperature.
    #
    # The participant will be fully available when the outside temperature
    # is above the temperature_cutoff point (in degrees Celsius). And
    # will have an availability of 0, when below this point.
    #
    # Users can also set their own availabilty curves on the node to overwrite
    # this behaviour.
    class TemperatureBasedPowerToHeatAdapter < FlexAdapter
      def producer_attributes
        attrs = super

        attrs[:availability] = Merit::Curve.new(
          @context.curves.rotate(availability_curve)
        )

        attrs
      end

      def inject!
        super

        # NOTE: is this neccessary in this case?
        target_api.availability = availability_curve.sum / availability_curve.length
      end

      private

      def producer_class
        Merit::Flex::VariableConsumer
      end

      # Internal: the availability curve can be directly set by the user,
      # or it can be calculated based on the outside temperature and
      # the temperature cutoff
      def availability_curve
        if availability_curve_from_node?
          availability_curve_from_node
        else
          availability_curve_based_on_temperature
        end
      end

      # Internal: the p2h pump should be fully available when temperature is
      # above the cutoff point, and fully unavailable when it's below.
      def availability_curve_based_on_temperature
        temperature_curve.map do |temp|
          temp < @node.config.temperature_cutoff ? 0.0 : 1.0
        end
      end

      # Internal: The curve of air temperatures in the region.
      def temperature_curve
        @context.curves.curve('weather/air_temperature', @node)
      end

      def availability_curve_from_node?
        availability_curve_from_node&.any?
      end

      # Internal: availibity curve set on the node (user uploaded)
      def availability_curve_from_node
        source_api.availability_curve
      end
    end
  end
end
