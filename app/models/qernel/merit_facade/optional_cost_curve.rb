# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Reuseable features for import and export adapters, where cost may be
    # defined as a constant or a curve.
    module OptionalCostCurve
      def inject!
        super
        target_api.marginal_costs = participant.marginal_costs
      end

      def producer_attributes
        attrs = super

        if cost_curve?
          attrs.delete(:marginal_costs)
          attrs[:cost_curve] = Merit::Curve.new(@context.curves.rotate(cost_curve))
        end

        attrs
      end

      private

      def cost_curve?
        cost_curve&.any?
      end

      def cost_curve
        source_api.marginal_cost_curve
      end
    end
  end
end
