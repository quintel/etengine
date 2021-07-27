# frozen_string_literal: true

module Qernel
  module Causality
    # Creates a merit order calculation for participants in the heat network.
    class HeatNetwork < Qernel::MeritFacade::Manager
      def initialize(graph)
        context = Qernel::MeritFacade::Context.new(
          self,
          graph,
          :steam_hot_water,
          :heat_network,
          Qernel::MeritFacade::UserDefinedSorter.new(graph.heat_network_order)
        )

        super(graph, context)
      end

      private

      def etsource_data
        Etsource::MeritOrder.new.import_heat_network
      end

      def start_hour
        # # Rotate curves so that the calculation is from April to March rather
        # # than January to December.
        # 8760 / 4
        0
      end
    end
  end
end
