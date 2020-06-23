# frozen_string_literal: true

module Qernel
  module FeverFacade
    class ProducerAdapter < Adapter
      # Contains methods and helpers for setting values on a node after the
      # Fever calculation has run.
      module Inject
        private

        # Internal: Sets demand and FLH attributes on the node.
        def inject_demand!
          producer   = participant.producer
          production = producer.output_curve.sum

          inject_aggregator_attributes!(production)

          # MWh -> MJ
          @node.demand = (production * 3600) / output_efficiency

          return unless production.positive?

          full_load_hours = production / total_value(:heat_output_capacity)

          @node[:full_load_hours]   = full_load_hours
          @node[:full_load_seconds] = full_load_hours * 3600
        end

        # Internal: If the node feeds energy into an aggregator, set the
        # share of the edges entering the aggregator so that any deficit of
        # demand from the producer will be met on the aggregator by its other
        # input edge.
        #
        # production - The total amount of energy output by the producer in MWh.
        #
        # For example
        #
        #    [Producer]  [Deficit]
        #           \      /
        #         [Aggregator]
        #
        # If the aggregator demands 50 but the producer only ends up supplying
        # 25, the share of the P->A edge is set to 0.5 (50%). The edge between
        # [Deficit] and [Aggregator] is expected to be a flexible and will
        # supply the rest.
        def inject_aggregator_attributes!(production)
          conv = @node.node

          return unless conv.groups.include?(:aggregator_producer)

          demand = participant.demand
          edge   = conv.output(:useable_heat).edges.first

          edge.share = demand.positive? ? production / demand : 1.0
        end

        # Internal: Inject input curves from the participant onto the node.
        def inject_input_curves!
          inject_input_curve(input_carrier)
        end

        # Internal: Receives a carrier name and injects the input curve for the
        # carrier onto the node.
        def inject_input_curve(carrier)
          curve_name = "#{carrier}_input_curve"

          return unless @node.respond_to?(curve_name)

          inject_curve!(full_name: curve_name) do
            Array.new(8760, &demand_callable_for_carrier(carrier))
          end
        end
      end
    end
  end
end
