# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Sets up a Merit participant which will be used last, using any excess
    # energy not exported or assigned to flexibles.
    class CurtailmentAdapter < FlexAdapter
      def inject!
        super

        input_edge = target_api.node.input(@context.carrier).edges.first
        demand     = participant.production(:mj)

        if input_edge.edge_type == :inversed_flexible
          # We need to override the calculation of an inversed flexible edge
          # and set the demand explicitly.
          input_edge.dataset_set(:value, demand)
          input_edge.dataset_set(:calculated, true)
        end

        target_api.demand = demand
      end

      def installed?
        # Curtailment is always available as an consumer-of-last-resort.
        true
      end

      private

      def producer_class
        Merit::Flex::BlackHole
      end

      def producer_attributes
        attrs = super

        attrs[:input_capacity_per_unit] = Float::INFINITY
        attrs[:number_of_units] = 1.0
        attrs.delete(:consumption_price)

        attrs
      end
    end
  end
end
