# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Adds data needed to calculate a dispatchable producer.
    class DispatchableAdapter < ProducerAdapter
      def inject!
        super

        target_api.dataset_lazy_set(:marginal_costs) do
          participant.marginal_costs.to_f
        end

        return unless @context.carrier == :electricity

        target_api.dataset_lazy_set(:profitability) do
          participant.profitability
        end

        target_api.dataset_lazy_set(:profit_per_mwh_electricity) do
          participant.profit_per_mwh_electricity
        end
      end

      def producer_attributes
        attrs = super

        attrs[:fixed_costs_per_unit] =
          source_api.send(:fixed_costs)

        attrs[:fixed_om_costs_per_unit] =
          source_api.send(:fixed_operation_and_maintenance_costs_per_year)

        attrs
      end
    end
  end
end
