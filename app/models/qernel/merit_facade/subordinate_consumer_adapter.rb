# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A consumer that adjusts its output based on demand already supplied by
    # a node in another time based calculation
    class SubordinateConsumerAdapter < ConsumerAdapter
      def initialize(*)
        super
        @subordinate_node = subordinate_node
      end

      def participant
        @participant ||=
          Merit::User.create(
            key: @node.key,
            load_curve: load_curve
          )
      end

      private

      def load_curve
        @context.curves.curve(
          @config.group,
          @subordinate_node
        )
      end

      def subordinate_node
        @context.graph.node(@config.subordinate_to).node_api
      end
    end
  end
end
