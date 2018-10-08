# frozen_string_literal: true

module Qernel::Plugins
  module Hydrogen
    class ConsumerAdapter < Adapter
      def inject!(_calculator)
        @converter.dataset_lazy_set(:hydrogen_input_curve) do
          demand_curve.to_a
        end
      end

      private

      def calculate_carrier_demand
        # We can't use input_of(:hydrogen) as the graph may not be calculated
        # at the time this method is called.
        @converter.demand * @converter.input(:hydrogen).conversion
      end
    end
  end
end
