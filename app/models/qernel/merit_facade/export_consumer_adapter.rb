# frozen_string_literal: true

module Qernel
  module MeritFacade
    # This class adapts an export consumer to act as must run. It uses the same methods for flexible edges as the export adapter.
    class ExportConsumerAdapter < ConsumerAdapter
      def inject!
        input_edge = target_api.node.input(@context.carrier).edges.first
        demand     = participant.production(:mj)

        target_api.demand = demand

        if input_edge.edge_type == :inversed_flexible
          # We need to override the calculation of an inversed flexible edge.
          # and set the demand explicitly.
          input_edge.dataset_set(:value, demand)
          input_edge.dataset_set(:calculated, true)
        end

        super
      end

      def input_of_carrier
        source_api.full_load_hours * source_api.input_capacity * MJ_TO_MHW
      end
    end
  end
end
