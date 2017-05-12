module Qernel::Plugins
  module Merit
    class ProducerAdapter < Adapter
      def self.factory(converter, graph, dataset)
        group = converter.dataset_get(:merit_order).group
        (group && group.to_sym == :import) ? ImportAdapter : self
      end

      def inject!
        full_load_hours = participant.full_load_hours

        if ! full_load_hours || full_load_hours.nan?
          full_load_seconds = full_load_hours = 0.0
        else
          full_load_seconds = full_load_hours * 3600
        end

        @converter[:full_load_hours]   = full_load_hours
        @converter[:full_load_seconds] = full_load_seconds
        @converter[:number_of_units]   = participant.number_of_units

        @converter.dataset_lazy_set(:marginal_costs) do
          participant.marginal_costs
        end

        @converter.dataset_lazy_set(:profitability) do
          participant.profitability
        end

        @converter.dataset_lazy_set(:profit_per_mwh_electricity) do
          participant.profit_per_mwh_electricity
        end

        @converter.demand =
          full_load_seconds *
          @converter.input_capacity *
          participant.number_of_units
      end

      private

      def producer_attributes
        attrs = super

        attrs[:marginal_costs] = @converter.marginal_costs

        attrs[:output_capacity_per_unit] =
          @converter.electricity_output_conversion * @converter.input_capacity

        attrs[:fixed_costs_per_unit] =
          @converter.send(:fixed_costs)

        attrs[:fixed_om_costs_per_unit] =
          @converter.send(:fixed_operation_and_maintenance_costs_per_year)

        attrs
      end

      def producer_class
        ::Merit::DispatchableProducer
      end
    end # ProducerAdapter
  end # Merit
end
