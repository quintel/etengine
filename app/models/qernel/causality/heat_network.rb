# frozen_string_literal: true

module Qernel
  module Causality
    module HeatNetwork
      # Creates a merit order calculation for participants in the LT heat network.
      class LowTemperature < Qernel::MeritFacade::Manager
        def initialize(graph)
          context = Qernel::MeritFacade::Context.new(
            self,
            graph,
            :steam_hot_water,
            :heat_network_lt,
            Qernel::MeritFacade::UserDefinedSorter.new(graph.heat_network_order_lt)
          )

          super(graph, context)
        end

        private

        def etsource_data
          Etsource::MeritOrder.new.import_heat_network_lt
        end
      end

      # Creates a merit order calculation for participants in the MT heat network.
      class MediumTemperature < Qernel::MeritFacade::Manager
        def initialize(graph)
          context = Qernel::MeritFacade::Context.new(
            self,
            graph,
            :steam_hot_water,
            :heat_network_mt,
            Qernel::MeritFacade::UserDefinedSorter.new(graph.heat_network_order_mt)
          )

          super(graph, context)
        end

        private

        def etsource_data
          Etsource::MeritOrder.new.import_heat_network_mt
        end
      end

      # Creates a merit order calculation for participants in the HT heat network.
      class HighTemperature < Qernel::MeritFacade::Manager
        def initialize(graph)
          context = Qernel::MeritFacade::Context.new(
            self,
            graph,
            :steam_hot_water,
            :heat_network_ht,
            Qernel::MeritFacade::UserDefinedSorter.new(graph.heat_network_order_ht)
          )

          super(graph, context)
        end

        private

        def etsource_data
          Etsource::MeritOrder.new.import_heat_network_ht
        end
      end
    end
  end
end
