# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Implements behaviour specific to the import interconnector.
    class ImportAdapter < ProducerAdapter
      def inject!
        super

        elec_link = target_api.converter.output(:electricity).links.first

        if elec_link.link_type == :flexible
          # We need to override the calculation of the flexible link and set the
          # demand explicitly.
          elec_link.dataset_set(:value, target_api.demand)
          elec_link.dataset_set(:calculated, true)
        end

        production = participant.production

        return unless production.positive?

        # Recalculate the price per MJ.
        total_price =
          carrier.cost_curve.to_enum.with_index.sum do |price, index|
            price * participant.load_at(index)
          end

        # Divide by production which is in MJ to set the cost per MJ.
        carrier.dataset_set(:cost_per_mj, total_price / production)
      end

      private

      def producer_class
        Merit::DispatchableProducer
      end

      def producer_attributes
        attrs = super

        cost_curve = carrier.cost_curve
        first_hour_cost = cost_curve.first

        unless cost_curve.all? { |val| val == first_hour_cost }
          attrs.delete(:marginal_costs)
          attrs[:cost_curve] = Merit::Curve.new(cost_curve)
        end

        attrs
      end

      def marginal_costs
        carrier.cost_curve.first
      end

      def output_capacity_per_unit
        source_api.electricity_output_capacity
      end

      def flh_capacity
        source_api.electricity_output_capacity
      end

      def carrier
        @context.graph.carrier(:imported_electricity)
      end
    end
  end
end
