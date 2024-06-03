# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A flex consumer whos demand is partly satisfied directly by another
    # participant,
    class SatisfiedDemandAdapter < FlexAdapter
      private

      def producer_attributes
        attrs = super

        attrs[:satisfied_demand_curve] = satisfied_demand_curve

        attrs
      end

      def producer_class
        Merit::Flex::WithSatisfiedDemand
      end

      # TODO: add node validation
      # TODO: make curve name a merit attribute and use public_send
      def satisfied_demand_curve
        @context.plugin.adapters[@config.relations[:input].to_sym].converter_curve
      end
    end
  end
end
