# frozen_string_literal: true

module Qernel
  module Causality
    # Creates a merit order calculation for participants in the hydrogen calculation.
    class Hydrogen < Qernel::MeritFacade::Manager
      def initialize(graph)
        context = Qernel::MeritFacade::Context.new(
          self,
          graph,
          :hydrogen,
          :hydrogen,
          # The order is regular, because low marginal cost should be served first
          Qernel::MeritFacade::UserDefinedSorter.new(graph.hydrogen_supply_order),
          # The order is inverted, because high consumption price should be served first
          Qernel::MeritFacade::UserDefinedSorter.new(graph.hydrogen_demand_order.reverse)
        )

        super(graph, context)
      end

      private

      def etsource_data
        Etsource::MeritOrder.new.import_hydrogen
      end
    end
  end
end
