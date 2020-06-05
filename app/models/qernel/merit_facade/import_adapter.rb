# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Implements behaviour specific to the import interconnector.
    class ImportAdapter < ProducerAdapter
      def initialize(*)
        super

        unless @context.carrier == :electricity
          raise "#{self.class.name} only supports electricity"
        end
      end

      # Public: Is the import interconnector installed?
      #
      # Interconnectors always have one unit, and normally have an availability
      # of 1.0. Therefore the default `installed?` is not sufficient to exclude
      # interconenctors which have no capacity.
      def installed?
        super && source_api.electricity_output_capacity.positive?
      end

      def inject!
        super

        elec_link = target_api.converter.output(:electricity).links.first

        if elec_link.link_type == :flexible
          # We need to override the calculation of the flexible link and set the
          # demand explicitly.
          elec_link.dataset_set(:value, target_api.demand)
          elec_link.dataset_set(:calculated, true)
        end

        return unless cost_curve? && participant.production.positive?

        target_api.marginal_costs = participant.marginal_costs
      end

      private

      def producer_class
        Merit::DispatchableProducer
      end

      def producer_attributes
        attrs = super

        if cost_curve?
          attrs.delete(:marginal_costs)
          attrs[:cost_curve] = Merit::Curve.new(cost_curve)
        end

        attrs
      end

      def cost_curve?
        cost_curve&.any?
      end

      def cost_curve
        source_api.marginal_cost_curve
      end

      def output_capacity_per_unit
        source_api.electricity_output_capacity
      end

      def flh_capacity
        source_api.electricity_output_capacity
      end
    end
  end
end
