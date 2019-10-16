# frozen_string_literal: true

module Qernel
  module Reconciliation
    class ConsumerAdapter < Adapter
      def inject!(_calculator)
        @converter.dataset_lazy_set(@context.curve_name(:input)) do
          demand_curve.to_a
        end
      end

      private

      def calculate_carrier_demand
        # We can't use input_of(carrier) as the graph may not be calculated at
        # the time this method is called.
        @converter.demand * @converter.input(@context.carrier).conversion
      end
    end
  end
end
