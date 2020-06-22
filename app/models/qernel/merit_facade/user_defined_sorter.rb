# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sorts dispatchable by the placement defined by the user in a UserSortable.
    class UserDefinedSorter
      def initialize(order)
        @order = order.map(&:to_sym)
      end

      def cost(node, _config)
        @order.index(node.key) || Float::INFINITY
      end
    end
  end
end
