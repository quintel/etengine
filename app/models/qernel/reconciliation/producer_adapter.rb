# frozen_string_literal: true

module Qernel
  module Reconciliation
    class ProducerAdapter < Adapter
      def self.factory(converter, context)
        if context.node_config(converter).behavior == :electrolyser
          ElectrolyserAdapter
        else
          self
        end
      end

      def inject!(_calculator)
        @converter.dataset_lazy_set(@context.curve_name(:output)) do
          demand_curve.to_a
        end
      end

      private

      def calculate_carrier_demand
        # We can't use output_of(carrier) as the graph may not be calculated at
        # the time this method is called.
        converter_demand * @converter.output(@context.carrier).conversion
      end
    end
  end
end
