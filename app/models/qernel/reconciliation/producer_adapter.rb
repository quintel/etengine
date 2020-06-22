# frozen_string_literal: true

module Qernel
  module Reconciliation
    class ProducerAdapter < Adapter
      def self.factory(node, context)
        if context.node_config(node).behavior == :electrolyser
          ElectrolyserAdapter
        else
          self
        end
      end

      def inject!(_calculator)
        @node.dataset_lazy_set(@context.curve_name(:output)) do
          demand_curve.to_a
        end
      end

      private

      def calculate_carrier_demand
        # We can't use output_of(carrier) as the graph may not be calculated at
        # the time this method is called.
        node_demand * output_slot.conversion
      end

      def output_slot
        carrier = @config.demand_carrier || @context.carrier

        @node.output(carrier) ||
          raise(<<~ERROR.squish)
            Expected a #{carrier} output on #{@node.key}, but none was
            found.
          ERROR
      end
    end
  end
end
