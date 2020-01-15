# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Helper class for creating and fetching curves from other Causality
    # components.
    #
    # For example, if an electricity merit order demand demands on the demand of
    # the same converter's heat output in the heat network, this will fetch a
    # reference to the curve from the heat network calcualtion (which has not
    # been run yet), so that values may be retrieved as they are ready.
    class SelfCurves
      def initialize(plugin, context)
        @plugin = plugin
        @context = context
      end

      # Public: Returns the SelfCurve from another Causality component.
      #
      # Returns a Causality::LazyCurve.
      def curve(name, converter)
        carrier, direction =
          Qernel::Causality::SelfDemandProfile
            .decode_name(name)
            .values_at(:carrier, :direction)

        case carrier
        when :electricity
          electricity_merit_self_curve(converter, carrier, direction)
        when :steam_hot_water
          heat_network_merit_self_curve(converter, carrier, direction)
        when :useable_heat, :heat
          fever_self_curve(converter, carrier, direction)
        else
          raise %(Unsupported curve: "self: #{name}" on #{converter.key})
        end
      end

      private

      # Internal: Creates a dynamic curve which reads demand from a electricity
      # Merit order participant.
      def electricity_merit_self_curve(converter, carrier, direction)
        # Curves read from the electricity merit order have an offset of 1 so
        # that the load for the current hour is based on the electricity load in
        # the previous hour. This is because the electricity loads are
        # calculated *after* the heat network.
        merit_self_curve(converter, carrier, direction, @plugin.merit, 1)
      end

      # Internal: Creates a dynamic curve which reads demand from a heat network
      # Merit order participant.
      def heat_network_merit_self_curve(converter, carrier, direction)
        merit_self_curve(converter, carrier, direction, @plugin.heat_network)
      end

      # Internal: Creates a dynamic curve which reads demand from a Merit order
      # participant.
      #
      # This should be provided with the name of the curve and the manager for
      # the merit order.
      #
      # converter - The ConverterApi of the node which will be assigned the
      #             curve.
      # carrier   - The name of the source slot carrier as a Symbol.
      # direction - The name of the source slot direction as a Symbol.
      # manager   - The MeritFacade::Manager from which the source curve will be
      #             taken.
      # offset    - Read `offset` hours from the past when fetching values from
      #             the source curve. This is necessary when the source curve is
      #             calculated after that of the current node. For example, the
      #             heat network hour 0 is calcualted before electricity hour 1,
      #             therefore a heat network calculation based on the
      #             electricity load must use the load from the previous hour.
      #
      # Returns a Merit::Curve.
      def merit_self_curve(converter, carrier, direction, manager, offset = 0)
        adapter = manager.adapters[converter.key]

        if adapter.nil?
          raise "Missing participant for \"self: ...\" curve: #{converter.key}"
        end

        curve = adapter.participant.load_curve

        conversion = carrier_to_carrier_conversion(
          converter, carrier, direction
        )

        Qernel::Causality::LazyCurve.new do |frame|
          source_frame = frame - offset
          source_frame.negative? ? 0.0 : curve[source_frame] * conversion
        end
      end

      # Internal: Creates a dynamic curve which reads the demand from a Fever
      # participant.
      def fever_self_curve(converter, carrier, direction)
        group = @plugin.fever.group(converter.fever.group)

        conversion = carrier_to_carrier_conversion(
          converter, carrier, direction
        )

        adapter = group.adapter(converter.key)

        if adapter.nil?
          raise 'Missing Fever participant for "self: ..." curve: ' \
                "#{converter.key}"
        end

        participant = adapter.participant.producer

        Qernel::Causality::LazyCurve.new do |frame|
          participant.output_at(frame) * conversion
        end
      end

      # Internal: Returns the conversion which allows converting energy from the
      # soruce curve (based on the given `carrier` and `direction`) to the
      # carrier used by the merit order.
      def carrier_to_carrier_conversion(converter, carrier, direction)
        Qernel::Causality::Conversion.conversion(
          converter.converter,
          carrier,
          direction,
          @context.carrier,
          target_slot_direction(converter)
        )
      end

      # Internal: Determines whether the slot used by the converter for the
      # carrier is an input or output.
      #
      # Returns a Symbol, or raises an error if the converter type is not
      # supported.
      def target_slot_direction(converter)
        type = @context.node_config(converter).type

        case type
        when :producer
          :output
        when :consumer
          :input
        else
          raise "Unsupported technology type #{type.inspect} encountered " \
                "when calculating \"self: ...\" curve for #{converter.key}"
        end
      end
    end
  end
end
