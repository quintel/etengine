# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Extracts marginal costs from a converter to be used to set their placement
    # in the merit order.
    class MarginalCostSorter
      def cost(converter)
        converter.marginal_costs
      end
    end
  end
end
