# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Adds a consumer to the merit order calculation whose demand is a share of
    # the total energy consumption for each hour. For example, if the loss share
    # is 0.2 (20%) and other demands sum to 10, demand for the consumption loss
    # user will be 2 and total demand for the frame will be 12.
    class ConsumptionLossAdapter < Adapter
      def initialize(*)
        super
        @loss_share = loss_share
      end

      def participant
        @participant ||= Merit::User.create(
          key: @converter.key,
          consumption_share: loss_share
        )
      end

      def inject!
        inject_curve!(:input) { @participant.load_curve }
      end

      def installed?
        true
      end

      private

      def loss_share
        links = target_api.converter.input(:loss).links

        if links.length != 1
          raise "Cannot find single loss link into #{@converter.key} for use " \
            'as a dynamic_loss participant in merit order calculation'
        end

        link = links.first
        link.rgt_output.conversion * link.parent_share
      end
    end
  end
end
