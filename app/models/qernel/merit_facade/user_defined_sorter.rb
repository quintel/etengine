# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sorts dispatchable by the placement defined by the user in a UserSortable.
    class UserDefinedSorter
      def initialize(order)
        @order = order.map(&:to_sym)
      end

      def cost(converter)
        @order.index(converter.key) || Float::INFINITY
      end
    end
  end
end
