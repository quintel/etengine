# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A module builder which can be used to support availability curves on a Merit participant.
    #
    # Merit itself supports this only on a few participant types, and generally requires that you
    # use one of these over the more general participants. The module therefore requires that you
    # name the alternate class to be used when an availability curve is set.
    #
    # For example, if an import participant is normally specified with a DispatchableProducer, it
    # might use a VariableDispatchableProducer when an availability curve is present. The adapter
    # would be defined like so:
    #
    #   class ImportAdapter
    #     include OptionalAvailabilityCurve.new(Merit::VariableDispatchableProducer)
    #
    #     private
    #
    #     def producer_class
    #       Merit::DispatchableProducer
    #     end
    #   end
    module OptionalAvailabilityCurve
      def producer_attributes
        attrs = super

        if availability_curve?
          attrs[:availability] = Merit::Curve.new(@context.curves.rotate(availability_curve))
        end

        attrs
      end

      def producer_class
        if availability_curve?
          variable_availability_producer_class
        else
          non_variable_availability_producer_class
        end
      end

      def inject!
        super

        if availability_curve?
          target_api.availability = availability_curve.sum / availability_curve.length
        end
      end

      private

      def variable_availability_producer_class
        raise NotImplementedError
      end

      def availability_curve?
        availability_curve&.any?
      end

      def availability_curve
        source_api.availability_curve
      end
    end
  end
end
