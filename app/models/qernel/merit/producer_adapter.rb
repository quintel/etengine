module Qernel
  module Merit
    class ProducerAdapter < Adapter
      def self.factory(converter, graph, dataset)
        case converter.merit_order.subtype
        when :must_run, :volatile
          AlwaysOnAdapter
        when :dispatchable
          group = converter.merit_order.group
          group == :import ? ImportAdapter : DispatchableAdapter
        end
      end

      def inject!
        full_load_hours = participant.full_load_hours

        if ! full_load_hours || full_load_hours.nan?
          full_load_seconds = full_load_hours = 0.0
        else
          full_load_seconds = full_load_hours * 3600
        end

        target_api[:full_load_hours]   = full_load_hours
        target_api[:full_load_seconds] = full_load_seconds
        target_api[:number_of_units]   = participant.number_of_units

        target_api.demand =
          full_load_seconds *
          flh_capacity *
          participant.number_of_units

        target_api.dataset_lazy_set(:electricity_output_curve) do
          @participant.load_curve.to_a
        end
      end

      private

      def producer_attributes
        attrs = super

        attrs[:marginal_costs] = marginal_costs
        attrs[:output_capacity_per_unit] = output_capacity_per_unit

        attrs
      end

      def producer_class
        ::Merit::DispatchableProducer
      end

      def marginal_costs
        source_api.marginal_costs
      end

      def output_capacity_per_unit
        source_api.electricity_output_conversion * source_api.input_capacity
      end

      # Internal: Capacity used to multiply full load seconds to determien the
      # resulting annual demand of the producer.
      def flh_capacity
        source_api.input_capacity
      end
    end # ProducerAdapter
  end # Merit
end
