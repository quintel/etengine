# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Adds data needed to calculate a dispatchable producer.
    class DispatchableAdapter < ProducerAdapter
      def inject!
        super

        return unless @context.carrier == :electricity

        target_api.dataset_lazy_set(:marginal_costs) do
          participant.marginal_costs.to_f
        end

        target_api.dataset_lazy_set(:profitability) do
          participant.profitability
        end

        target_api.dataset_lazy_set(:profit_per_mwh_electricity) do
          participant.profit_per_mwh_electricity
        end

        target_api.dataset_lazy_set(:revenue_hourly_electricity) do
          participant.revenue
        end

        target_api.dataset_lazy_set(:revenue_hourly_electricity_per_plant) do
          if source_api.number_of_units.positive?
            participant.revenue / source_api.number_of_units
          else
            0.0
          end
        end

        target_api.dataset_lazy_set(:revenue_hourly_electricity_per_mwh) do
          participant.revenue_per_mwh
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

      def marginal_costs
        @context.dispatchable_sorter.cost(@node, @config)
      end
    end
  end
end
