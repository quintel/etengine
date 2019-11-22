# frozen_string_literal: true

module Qernel
  module Causality
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
          # Skip participants which use "self" curves, sourced from the
          # electricity merit order or Fever. These are added in setup_dynamic.
          next if adapter.config.group.to_s.start_with?('self')

          participant = adapter.participant
          @order.add(participant) if adapter.installed?
        end
      end

      def inject_values!
        setup_dynamic
        @order.calculate

        super
      end

      private

      # Internal: Installs participants whose curves depend on the calcualtion
      # of the electricity merit order or Fever, which are not available at the
      # time "setup" is called.
      def setup_dynamic
        each_adapter do |adapter|
          next unless adapter.config.group.to_s.start_with?('self')

          participant = adapter.participant
          @order.add(participant) if adapter.installed?
        end
      end

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
