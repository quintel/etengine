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
          Qernel::MeritFacade::UserDefinedSorter.new(graph.hydrogen_supply_order),
          # Should become the hydrogen demand order
          Qernel::MeritFacade::UserDefinedSorter.new(graph.hydrogen_demand_order)
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
