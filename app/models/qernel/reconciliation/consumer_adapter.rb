# frozen_string_literal: true

module Qernel
  module Reconciliation
    # Represents a form of consumption within the reconciliation calculation.
    class ConsumerAdapter < Adapter
      def self.factory(converter, context)
        if context.node_config(converter).behavior == :subordinate
          SubordinateConsumerAdapter
        else
          self
        end
      end

      def inject!(_calculator)
        @converter.dataset_lazy_set(@context.curve_name(:input)) do
          demand_curve.to_a
        end
      end

      private

      def calculate_carrier_demand
        # We can't use input_of(carrier) as the graph may not be calculated at
        # the time this method is called.
        converter_demand * input_slot.conversion
      end

      def input_slot
        carrier = @config.demand_carrier || @context.carrier

        @converter.input(carrier) ||
          raise(<<~ERROR.squish)
            Expected a #{carrier} output on #{@converter.key}, but none was
            found.
          ERROR
      end
    end
  end
end
