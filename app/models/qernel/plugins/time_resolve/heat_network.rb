# frozen_string_literal: true

module Qernel
  module Plugins
    class TimeResolve
      # Creates a merit order calculation for participants in the heat network.
      class HeatNetwork < Qernel::MeritFacade::Manager
        def initialize(graph)
          context = Qernel::MeritFacade::Context.new(
            self, graph, :steam_hot_water, :heat_network
          )

          super(graph, context)
        end

        # TODO: Refactor. This is Manager#setup without the total demand curve.
        def setup
          @order = Merit::Order.new

          each_adapter do |adapter|
            participant = adapter.participant
            @order.add(participant) if adapter.installed?
          end
        end

        private

        # TODO: Refactor. This is Manager#converters with one change.
        def converters(type, subtype)
          type_data = Etsource::MeritOrder.new.import_heat_network[type.to_s]

          (type_data || {}).map do |key, profile|
            converter = @graph.converter(key)

            next if !subtype.nil? && converter.merit_order.subtype != subtype

            converter.converter_api.load_profile_key = profile

            converter
          end.compact
        end
      end
    end
  end
end
