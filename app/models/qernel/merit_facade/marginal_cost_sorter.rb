# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Extracts marginal costs from a node to be used to set their placement
    # in the merit order.
    class MarginalCostSorter
      def cost(node, config)
        if config.type == :flex
          node.max_consumption_price
        else
          node.marginal_costs
        end
      end
    end
  end
end
