# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Extracts marginal costs from a node to be used to set their placement
    # in the merit order.
    class MarginalCostSorter
      def cost(node, config)
        config.type == :flex ? :null : node.marginal_costs
      end
    end
  end
end
