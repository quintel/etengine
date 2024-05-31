# frozen_string_literal: true

# require 'delegate'

module Qernel
  module MeritFacade
    class HybridOffshoreAdapter < AlwaysOnAdapter
      attr_reader :converter_curve

      def initialize(node, context)
        super

        # input capacity of the output node
        @output_input_capacity = output_node.node_api.input_capacity * output_node.node_api.number_of_units
        @converter_input_capacity = converter_node.node_api.input_capacity * converter_node.node_api.number_of_units

        @clearing = Array.new(8760, 0.0)
        @curtailed = Array.new(8760, 0.0)

        @converter_curve = Qernel::Causality::ActiveLazyCurve.new do |frame|
          @clearing[frame] * -1
        end
      end

      def inject!
        super

        total_demand = participant.production
        curtailment_demand = @curtailed.sum

        find_edge(curtailment_node).dataset_set(:share, safe_div(curtailment_demand, total_demand))
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

        # lamba function that takes the frame and subracts the clearing, minimum with the cable in
        # and that keeps track of the unfilled demand (that will become curtailment!)
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

      def converter_node
        @context.graph.node(@config.relations[:converter])
      end

      def output_node
        @context.graph.node(@config.relations[:output])
      end

      def curtailment_node
        @context.graph.node(@config.relations[:curtailment])
      end
    end
  end
end
