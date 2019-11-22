# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Adds a consumer to the merit order calculation whose demand is a share of
    # all the other demands. For example, if the consumption share is 0.2 (20%)
    # and other demands sum to 10, demand for the consumption loss user will be
    # 2, and total demand for the frame will be 12.
    class ConsumptionLossAdapter < Adapter
      def participant
        @participant ||= Merit::User.create(
          key: @converter.key,
          consumption_share: consumption_share
        )
      end

      def inject!
        target_api.dataset_lazy_set(@context.curve_name(:input)) do
          @participant.load_curve.to_a
        end

        target_api.demand = @participant.load_curve.sum * 3600
      end

      def installed?
        true
      end

      private

      def consumption_share
        links = target_api.converter.input(:loss).links

        if links.length != 1
          raise "Cannot find single loss link into #{@converter.key} for use " \
            'as a consumption_loss in merit order calculation'
        end

        link = links.first
        link.rgt_output.conversion * link.parent_share
      end
    end
  end
end
