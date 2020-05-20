# frozen_string_literal: true

module Qernel
  module Causality
    # Creates a merit order calculation for participants in the electricity
    # merit order.
    class Electricity < Qernel::MeritFacade::Manager
      private

      def flex_groups
        Etsource::Config.flexibility_groups(@context.attribute)
      end

      def inject_graph_values!
        carrier = @context.graph.carrier(@context.carrier)

        carrier.dataset_lazy_set(:cost_curve) do
          @curves.derotate(@order.price_curve.to_a)
        end

        carrier.dataset_lazy_set(:demand_curve) do
          @curves.derotate(@order.demand_curve.to_a)
        end
      end
    end
  end
end
