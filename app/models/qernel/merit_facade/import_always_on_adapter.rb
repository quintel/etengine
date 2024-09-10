# frozen_string_literal: true

module Qernel
  module MeritFacade
    # This class adapts an import producer to act as must run. It uses the same methods for flexible edges as the import adapter.
    class ImportAlwaysOnAdapter < AlwaysOnAdapter
      def inject!
        super
        elec_edge = target_api.node.output(:electricity).edges.first

        return unless elec_edge.edge_type == :flexible

        # We need to override the calculation of the flexible edge and set the
        # demand explicitly.
        elec_edge.dataset_set(:value, target_api.demand)
        elec_edge.dataset_set(:calculated, true)
      end
    end
  end
end
