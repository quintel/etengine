# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A flex consumer whose demand is partly satisfied directly by another
    # participant. Currently, the adapter satisfying the demand has to be of type
    # HybridOffshore.
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

      def satisfied_demand_curve
        @context.plugin.adapters[@config.relations[:input].to_sym].converter_curve
      end
    end
  end
end
