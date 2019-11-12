# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sets up household power-to-heat in Merit whose electricty demand needs to
    # be communicated to a Fever group for conversion to heat.
    class HouseholdPowerToHeatAdapter < FlexAdapter
      private

      # A Merit participant whose energy is not available to be re-emitted, and
      # where consumption needs to be communicated to a delegate.
      class DelegatingBlackHole < Merit::Flex::BlackHole
        def initialize(opts)
          super
          @delegate = opts[:delegate]
        end

        def assign_excess(frame, amount)
          input_cap = @input_capacity + load_curve.get(frame)

          amount = input_cap if input_cap < amount
          stored = @delegate.store_excess(frame, amount)

          load_curve.set(frame, load_curve.get(frame) - stored)

          stored
        end
      end

      def producer_attributes
        attrs = super

        # Yuck.
        attrs[:delegate] = @context.graph.plugin(:time_resolve)
          .fever.group(:households_hot_water).calculator

        # TODO: Does input capacity /efficiency prevent the need to model input
        # constraints in Fever?
        attrs[:input_capacity_per_unit] = source_api.input_capacity

        # Do not emit anything; it has been converted to hot water.
        #
        # TODO This may not be necessary since BlackHole always sets max_load_at
        # to zero.
        attrs[:output_capacity_per_unit] = 0.0

        attrs
      end

      def producer_class
        DelegatingBlackHole
      end

      def excess_share
        1.0
      end
    end
  end
end
