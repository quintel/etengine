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
        @clearing = Array.new(8760)

        @converter_curve = Qernel::Causality::LazyCurve.new do |frame|
          @clearing[frame] * -1
        end
      end

      private

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
      # energy is located to other components
      def constrain(point, amount)
        converted = to_converter(amount)
        @clearing[point] = converted

        [amount - converted, @output_input_capacity].min
      end

      # The amount that flows to the converter in that hour
      def to_converter(amount)
        [amount - @output_input_capacity, @converter_input_capacity].min
      end

      # def curtailment_curve
      #   # empty curve that will be filled
      # end

      # def output_curve
      #   # can we also track this witinh the constarint method?
      #   # this is what shoudl go into the cable -> so what goes into the market?
      # end

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
