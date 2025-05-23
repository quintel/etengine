# frozen_string_literal: true

require 'delegate'

module Qernel
  module MeritFacade
    # Enables always-on battery parks in the merit order.
    #
    # See AlwaysOnBatteryPark.
    #
    # The producer output and battery loads are calculated by the AlwaysOnBatteryPark, and Merit
    # only needs to know the final combined load.
    #
    # The adapter must be configured with keys for the battery, output, and curtailment nodes with
    # the following structure expected:
    #
    #                    +----------------------------------+
    #                    v                                  |
    #               +--------+                              |
    #     ...  <--  | Output |  <-                          |
    #               +--------+    \ +---------+       +----------+
    #                               | Battery |  <--  | Producer |
    #       +----------------+    / +---------+       +----------+
    #       | Unused storage |  <-                          |
    #       +----------------+                              |
    #                                                       |
    #          +-------------+                              |
    #          | Curtailment |  <---------------------------+
    #          +-------------+
    #
    # The adapter will set curves for:
    #
    # * Hourly energy output on the producer node (includes energy sent to the output, battery, and
    #   curtailment).
    # * Hourly battery input on the battery node.
    # * Hourly battery output on the battery node.
    # * Hourly curtailed loads on the curtailment node.
    # * Combined hourly energy output by the technology on the output node.
    #
    class AlwaysOnBatteryParkAdapter < ProducerAdapter
      # Wraps a storage node to fake participation in the merit order, allowing the existing
      # StorageAdapter to be used.
      class StorageWrapper < SimpleDelegator
        def merit_order
          @merit_order ||= Atlas::NodeAttributes::MeritOrder.new(
            type: :flex, subtype: :storage
          )
        end
      end

      def initialize(node, context)
        super

        @storage = StorageAdapter.new(StorageWrapper.new(storage_node), @context)

        @park = AlwaysOnBatteryPark.new(
          production_curve: (
            @context.curves.curve(@config.group, @node) *
            source_api.output_of_carrier(@context.carrier)
          ).to_a,
          output_capacity: output_node.query.electricity_output_capacity,
          storage: @storage.participant
        )
      end

      def inject!
        total_demand = @park.production_curve.sum

        curtailment_demand = @park.curtailment_curve.sum
        storage_demand = @park.storage_input_curve.sum
        output_demand = @park.producer_output_curve.sum

        inject_costs!

        find_edge(curtailment_node).dataset_set(:share, safe_div(curtailment_demand, total_demand))
        find_edge(storage_node).dataset_set(:share, safe_div(storage_demand, total_demand))
        find_edge(output_node).dataset_set(:share, safe_div(output_demand, total_demand))

        # Producer node
        # -------------

        target_api.dataset_lazy_set(:electricity_output_curve) do
          @context.curves.derotate(@park.production_curve)
        end

        # Curtailment node
        # ----------------

        curtailment_node.dataset_lazy_set(:electricity_input_curve) do
          @context.curves.derotate(@park.curtailment_curve)
        end

        # Output node
        # -----------

        output_node.dataset_lazy_set(:electricity_output_curve) do
          @context.curves.derotate(@park.output_curve)
        end

        # Storage node
        # ------------

        @storage.inject!
      end

      private

      def find_edge(consumer, carrier = @context.carrier)
        edge = target_api.output_edges.find { |e| e.lft_node == consumer }

        unless edge
          raise "Couldn't find a #{carrier.inspect} edge between #{target_api.key} " \
                "and #{consumer.key}"
        end

        edge
      end

      def safe_div(num, denom)
        num.zero? || denom.zero? ? 0.0 : num / denom
      end

      def producer_attributes
        attrs = super
        attrs[:load_curve] = Merit::Curve.new(@park.output_curve)
        attrs
      end

      def producer_class
        Merit::CurveProducer
      end

      def storage_node
        @context.graph.node(@config.relations[:storage])
      end

      def output_node
        @context.graph.node(@config.relations[:output])
      end

      def curtailment_node
        @context.graph.node(@config.relations[:curtailment])
      end

      def inject_costs!
        target_api.dataset_lazy_set(:revenue_hourly_electricity) do
          participant.revenue
        end

        target_api.dataset_lazy_set(:revenue_hourly_electricity_per_mwh) do
          participant.revenue_per_mwh
        end
      end
    end
  end
end
