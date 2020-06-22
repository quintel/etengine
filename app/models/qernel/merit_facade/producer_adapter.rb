# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Base class which sets up producers in Merit.
    class ProducerAdapter < Adapter
      def self.factory(node, context)
        config = context.node_config(node)

        case config.subtype
        when :must_run, :volatile
          curtailment = config.production_curtailment
          curtailment&.positive? ? CurtailedAlwaysOnAdapter : AlwaysOnAdapter
        when :backup
          BackupAdapter
        when :dispatchable
          group = config.group
          group == :import ? ImportAdapter : DispatchableAdapter
        end
      end

      def inject!
        install_demand!
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

      def full_load_hours_from_participant
        participant.full_load_hours
      end

      def number_of_units_from_participant
        participant.number_of_units
      end

      def install_demand!
        # Do not set demand or FLH when based on a "self" curve as these will
        # be set by the other Causality component adapter. i.e. when a CHP
        # participates as an electricity and heat producer, and the heat part is
        # determined by the electricity load (self: electricity_output_curve),
        # then the demand and FLH are set by the electricity adapter, and should
        # be left alone by the heat adapter.
        return if @config.group.to_s.start_with?('self:')

        full_load_hours = full_load_hours_from_participant

        full_load_seconds =
          if !full_load_hours || full_load_hours.nan?
            full_load_hours = 0.0
          else
            full_load_hours * 3600
          end

        target_api[:full_load_hours]   = full_load_hours
        target_api[:full_load_seconds] = full_load_seconds
        target_api[:number_of_units]   = number_of_units_from_participant

        target_api.demand =
          full_load_seconds *
          flh_capacity *
          target_api.number_of_units
      end
    end
  end
end
