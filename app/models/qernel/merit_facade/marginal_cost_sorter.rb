# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Extracts marginal costs from a node to be used to set their placement
    # in the merit order.
    class MarginalCostSorter
      def cost(node, config)
        node.marginal_costs || (config.type == :flex ? 0.0 : nil)
      end
    end
  end
end
