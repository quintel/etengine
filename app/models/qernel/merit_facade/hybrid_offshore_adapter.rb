# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Represents a Hybrid Offshore Park.
    #
    # This adapter has to be attached to the main volatile producer.
    #
    # A hybrid offshore park consist of two e-cables, one output from sea to land,
    # one input from land to sea; one volatile producer; a possible curtailment of the producer;
    # and a converter (e.g electrolyser) that can also bid on the main market through the input
    # cable. This converter should act as a Flex with SatifiedDemand, as the producer may set a load
    # directly, bypassing the market to circumvent curtailment.
    #
    # The following structure is expected:
    #
    #                                                       +-------+
    #                    +--------------------------------- | Input | <-- ...
    #                    v                                  +-------+
    #               +-----------+
    #     ...  <--  | Converter |  <------------------------\
    #               +-----------+                     +-------------+
    #                                  +------------- | V. Producer |
    #               +--------+         |              +-------------+
    #     ...  <--  | Output |  <------+                    |
    #               +--------+                              |
    #                                                       |
    #               +-------------+                         |
    #               | Curtailment |  <----------------------+
    #               +-------------+
    #
    # The adapter will set curves for:
    #
    # * Hourly energy output on the producer node (includes energy sent to the output, converter,
    #   and curtailment).
    # * Hourly input on the output node.
    # * Hourly output on the input node.
    # * Hourly curtailed loads on the curtailment node.
    # * Combined hourly energy output by the technology on the output node.
    #
    class HybridOffshoreAdapter < AlwaysOnAdapter
      attr_reader :converter_curve

      def initialize(node, context)
        super

        # Input capacity of the output node
        @output_input_capacity = (
          output_node.node_api.input_capacity * output_node.node_api.number_of_units
        )
        # Input capacity of the converter node
        @converter_input_capacity = (
          converter_node.node_api.input_capacity *
          converter_node.node_api.number_of_units *
          converter_node.node_api.availability
        )

        @clearing = Array.new(8760, 0.0)
        @curtailed = Array.new(8760, 0.0)

        @converter_curve = Qernel::Causality::ActiveLazyCurve.new do |frame|
          @clearing[frame] * -1
        end
      end

      def inject!
        super

        total_demand = participant.production
        curtailment_demand = @curtailed.sum * 3600

        calculate_curves!

        # The curtailment egde is a share edge, so we calculate the share
        find_edge(curtailment_node).dataset_set(:share, safe_div(curtailment_demand, total_demand))

        # The converter node is a constant edge, so we set the demand directly
        find_edge(converter_node).dataset_set(:share, @converter_curve.sum * 3600)

        output_node.dataset_lazy_set(:electricity_input_curve) do
          @context.curves.derotate(@output_curve)
        end

        curtailment_node.dataset_lazy_set(:electricity_input_curve) do
          @context.curves.derotate(@curtailed)
        end

        input_node.dataset_lazy_set(:electricity_output_curve) do
          @context.curves.derotate(@input_curve)
        end
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

      def producer_class
        Merit::ConstrainedVolatileProducer
      end

      def producer_attributes
        attrs = super

        attrs[:constraint] = ->(point, amount) { constrain(point, amount) }

        attrs
      end

      # Calculates the energy that is constrained from going on the market. The constrained
      # energy is located to other components.
      #
      # Returns the energy that is allowed to go on the market
      def constrain(point, amount)
        converted = to_converter(amount)
        @clearing[point] = converted

        to_market = [amount - converted, @output_input_capacity].min
        @curtailed[point] = amount - converted - to_market

        to_market
      end

      # The amount that flows to the converter in that hour
      def to_converter(amount)
        (amount - @output_input_capacity).clamp(0.0, @converter_input_capacity)
      end

      # Caluclate the curves after Merit calculations have finished
      def calculate_curves!
        @output_curve = Array.new(8760, 0.0)
        @input_curve = Array.new(8760, 0.0)
        @converter_curve = Array.new(8760, 0.0)

        8760.times do |frame|
          converted = [
            participant.load_curve[frame] - @curtailed[frame],
            converter_adapter.participant.load_curve[frame].abs
          ].min

          @converter_curve[frame] = converted
          @output_curve[frame] = participant.load_curve[frame] - @curtailed[frame] - converted
          @input_curve[frame] = converter_adapter.participant.load_curve[frame].abs - converted
        end
      end

      # Get relations adapters and nodes

      def converter_adapter
        @context.plugin.adapters[@config.relations[:converter].to_sym]
      end

      def converter_node
        @context.graph.node(@config.relations[:converter])
      end

      def output_node
        @context.graph.node(@config.relations[:output])
      end

      def input_node
        @context.graph.node(@config.relations[:input])
      end

      def curtailment_node
        @context.graph.node(@config.relations[:curtailment])
      end
    end
  end
end
