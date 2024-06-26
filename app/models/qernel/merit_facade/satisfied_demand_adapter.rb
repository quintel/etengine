# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A flex consumer whose demand is partly satisfied directly by another
    # participant. Currently, the adapter satisfying the demand has to be of type
    # HybridOffshore.
    # Optionally, the related participant can also constrain the energy this
    # partcicipant is allowed to bid on the market.
    class SatisfiedDemandAdapter < FlexAdapter
      private

      def producer_attributes
        attrs = super

        attrs[:satisfied_demand_curve] = satisfied_demand_curve
        attrs[:constraint] = -> (point, amount) { constrain(point, amount) }

        attrs
      end

      def producer_class
        Merit::Flex::WithSatisfiedDemand
      end

      def satisfied_demand_curve
        related_adapter.converter_curve
      end

      def constraint_curve
        @constraint_curve ||= related_adapter.converter_constraint_curve
      end

      def constrain(point, amount)
        [constraint_curve[point], amount].min
      end

      def related_adapter
        @context.plugin.adapters[@config.relations[:input].to_sym]
      end
    end
  end
end
