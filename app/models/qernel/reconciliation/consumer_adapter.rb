# frozen_string_literal: true

module Qernel
  module Reconciliation
    # Represents a form of consumption within the reconciliation calculation.
    class ConsumerAdapter < Adapter
      def self.factory(node, context)
        if context.node_config(node).behavior == :subordinate
          SubordinateConsumerAdapter
        else
          self
        end
      end

      def inject!(_calculator)
        @node.dataset_lazy_set(@context.curve_name(:input)) do
          demand_curve.to_a
        end
      end

      private

      def calculate_carrier_demand
        # We can't use input_of(carrier) as the graph may not be calculated at
        # the time this method is called.
        node_demand * input_slot.conversion
      end

      # Internal: Consumers only have an input capacity, on the slot of their demand carrier.
      def installed_input_capacity
        slot_capacity(input_slot)
      end

      def input_slot
        carrier = @config.demand_carrier || @context.carrier

        @node.input(carrier) ||
          raise(<<~ERROR.squish)
            Expected a #{carrier} output on #{@node.key}, but none was
            found.
          ERROR
      end
    end
  end
end
