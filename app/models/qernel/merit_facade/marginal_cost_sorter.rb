# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Extracts marginal costs from a node to be used to set their placement
    # in the merit order.
    class MarginalCostSorter
      def cost(node, _config)
        node.marginal_costs || :null
      end
    end
  end
end
