# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Base class which sets up producers in Merit.
    class ProducerAdapter < Adapter
      def self.factory(node, context)
        config = context.node_config(node)

        case config.subtype
        when :dispatchable
          DispatchableAdapter
        when :must_run, :volatile
          curtailment = config.production_curtailment
          curtailment&.positive? ? CurtailedAlwaysOnAdapter : AlwaysOnAdapter
        when :import
          ImportAdapter
        when :backup
          BackupAdapter
        when :always_on_battery_park
          AlwaysOnBatteryParkAdapter
        else
          raise "Unknown #{context.attribute}.subtype " \
                "#{config.subtype.to_s.inspect} for #{node.key}"
        end
      end

      def inject!
        install_demand!
        inject_self_shares!
        inject_curve!(:output) { @participant.load_curve }
      end

      private

      def inject_self_shares!
        return unless @config.subtype == :must_run
        return unless @config.group.to_s.delete(' ') == 'self:electricity_output_curve'
        return unless source_api.merit_order&.subtype == :dispatchable
        return if @context.hydrogen?

        # This heat producer is also part of the electricity merit order, where it behaves as a
        # dispatchable. Since it is dispatchable, the electricity load for hour n is not known until
        # the heat network is calculated for n + 1. Therefore the last hour of electricity doesn't
        # generate any heat in the network.
        #
        # To ensure that the energy flows from the node are consistent with the hourly heat
        # calculation, we must adjust the heat output.
        #
        # See https://github.com/quintel/etengine/issues/1175

        heat_output = target_api.output(@context.carrier)

        load_curve = @participant.load_curve
        sum = load_curve.sum

        # The last hour of heat is lost.
        excess = load_curve.get(8760)

        return if sum.zero? || excess.zero?

        excess_share = heat_output.conversion * (excess / (sum + excess))

        heat_output.conversion -= excess_share
      end

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
        source_api.marginal_costs || :null
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
