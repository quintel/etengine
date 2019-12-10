# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Base class which sets up producers in Merit.
    class ProducerAdapter < Adapter
      def self.factory(converter, context)
        config = context.node_config(converter)

        case config.subtype
        when :must_run, :volatile
          AlwaysOnAdapter
        when :dispatchable
          group = config.group
          group == :import ? ImportAdapter : DispatchableAdapter
        end
      end

      def inject!
        full_load_hours = participant.full_load_hours

        full_load_seconds =
          if !full_load_hours || full_load_hours.nan?
            full_load_hours = 0.0
          else
            full_load_hours * 3600
          end

        target_api[:full_load_hours]   = full_load_hours
        target_api[:full_load_seconds] = full_load_seconds
        target_api[:number_of_units]   = participant.number_of_units

        target_api.demand =
          full_load_seconds *
          flh_capacity *
          participant.number_of_units

        inject_curve!(:output) { @participant.load_curve }
      end

      private

      def producer_attributes
        attrs = super

        attrs[:marginal_costs] = marginal_costs
        attrs[:output_capacity_per_unit] = output_capacity_per_unit

        attrs
      end

      def producer_class
        Merit::DispatchableProducer
      end

      def marginal_costs
        source_api.marginal_costs
      end

      def output_capacity_per_unit
        source_api.public_send(@context.carrier_named('%s_output_conversion')) *
          source_api.input_capacity
      end

      # Internal: Capacity used to multiply full load seconds to determien the
      # resulting annual demand of the producer.
      def flh_capacity
        source_api.input_capacity
      end
    end
  end
end
