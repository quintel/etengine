# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A flex consumer whos demand is partly satisfied directly by another
    # participant,
    class SatisfiedDemandAdapter < FlexAdapter
      def inject!
        super

        input_edge.dataset_set(:share, participant.production)
      end

      private

      def producer_attributes
        attrs = super

        attrs[:satisfied_demand_curve] = satisfied_demand_curve

        attrs
      end

      def producer_class
        Merit::Flex::WithSatisfiedDemand
      end

      # TODO: add node validation
      # TODO: make curve name a merit attribute and use public_send
      def satisfied_demand_curve
        @context.plugin.adapters[@config.relations[:input].to_sym].converter_curve
      end

      # Input edge should be a constant edge
      def input_edge
        input_node = @context.graph.node(@config.relations[:input])
        edge = target_api.input_edges.find { |e| e.rgt_node == input_node }

        unless edge
          raise "Couldn't find a #{@context.carrier.inspect} edge between #{target_api.key} " \
                "and #{input_node.key}"
        end

        edge
      end
    end
  end
end
