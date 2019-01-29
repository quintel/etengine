module Qernel::Plugins
  module Merit
    class HouseholdPowerToHeatAdapter < FlexAdapter
      private

      class DelegatingBlackHole < ::Merit::Flex::BlackHole
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
        attrs[:delegate] =
          @graph.plugin(:time_resolve).fever.group(:hot_water).calculator

        # TODO Does input capacity /efficiency prevent the need to model input
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
    end # PowerToHeatAdapter
  end # Merit
end
