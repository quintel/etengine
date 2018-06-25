module Qernel::Plugins
  module Merit
    # Adds data needed to calculate profitability of a dispatchable producer.
    class DispatchableAdapter < ProducerAdapter
      def inject!
        super

        @converter.dataset_lazy_set(:marginal_costs) do
          participant.marginal_costs.to_f
        end

        @converter.dataset_lazy_set(:profitability) do
          participant.profitability
        end

        @converter.dataset_lazy_set(:profit_per_mwh_electricity) do
          participant.profit_per_mwh_electricity
        end
      end

      def producer_attributes
        attrs = super

        attrs[:fixed_costs_per_unit] =
          @converter.send(:fixed_costs)

        attrs[:fixed_om_costs_per_unit] =
          @converter.send(:fixed_operation_and_maintenance_costs_per_year)

        attrs
      end
    end
  end
end
