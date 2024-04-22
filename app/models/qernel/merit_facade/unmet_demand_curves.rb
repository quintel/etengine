# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Helper class for creating and fetching curves based on other Causality
    # components. Calculating the unmet demand for the carrier_to, so that
    # other components can pick this demand up.
    #
    # For example, for power to heat a hydrogen backup burner has to look at the
    # unmet heat demand from the other burner that works on excess electricity.
    class UnmetDemandCurves
      def initialize(plugin, context)
        @plugin = plugin
        @context = context
      end

      # Public: Returns the UnmetDemandCurve from another Causality component.
      #
      # Returns a Causality::LazyCurve.
      def curve(name, node)
        carrier_from, carrier_to =
          Qernel::Causality::SelfDemandProfile
            .decode_name(name, :unmet_demand)
            .values_at(:carrier_from, :carrier_to)

        manager =
          case carrier_from
          when :electricity
            @plugin.merit
          when :steam_hot_water
            @plugin.heat_network.manager_for(node)
          when :hydrogen
            @plugin.hydrogen
          else
            raise %(Unsupported curve: "self: #{name}" on #{node.key})
          end

        # times its own carrier conversions!
        unmet_demand_curve(node, carrier_from, carrier_to, manager)
      end

      private

      # Internal: Creates a dynamic curve which reads demand from a Merit order
      # participant.
      #
      # This should be provided with the name of the curve and the manager for
      # the merit order.
      #
      # In contrary to the SelfCurves we do not have to chek for the offset, as
      # unmet demand currently only affects power to heat
      #
      # node - The NodeApi of the node which will be assigned the
      #             curve.
      # carrier   - The name of the source slot carrier as a Symbol.
      # direction - The name of the source slot direction as a Symbol.
      # manager   - The MeritFacade::Manager from which the source curve will be
      #             taken.
      #
      # Returns a Merit::Curve.
      def unmet_demand_curve(node, carrier_from, carrier_to, manager)
        adapter = manager.adapters[node.key]

        if adapter.nil?
          raise "Missing participant for \"unmet-demand: ...\" curve: #{node.key}"
        end

        if adapter.config.type != :flex && (
            adapter.config.subtype != :power_to_heat_industry ||
            adapter.config.subtype != :power_to_heat
          )
          raise "Participant should be of type power_to_heat_industry: #{node.key}"
        end

        curve = adapter.participant.load_curve

        conversion = carrier_to_carrier_conversion(
          node, carrier_from, carrier_to
        )

        filter = merit_curve_value_filter(adapter.config.type, :input)
        subtraction_profile = adapter.subtraction_profile
        offset = hour_offset

        Qernel::Causality::LazyCurve.new do |frame|
          source_frame = frame - offset

          value =
            if source_frame.negative?
              0.0
            elsif filter
              filter.call(curve[source_frame]) * conversion
            else
              curve[source_frame] * conversion
            end

          subtraction_profile[frame] - value
        end
      end

      # Internal: Values from Merit curves can be used verbatim, except when the
      # participant is a flexibility technology. In those cases, input is
      # represented as a negative, and output as a positive.
      def merit_curve_value_filter(type, direction)
        return nil unless type == :flex

        if direction == :input
          ->(value) { value.negative? ? value.abs : 0.0 }
        else
          ->(value) { value.positive? ? value : 0.0 }
        end
      end

      # Internal: Returns the conversion which allows converting energy from the
      # soruce curve (based on the given `carrier` and `direction`) to the
      # carrier used by the merit order.
      def carrier_to_carrier_conversion(node, carrier_from, carrier_to)
        Qernel::Causality::Conversion.conversion(
          node.node,
          carrier_from,
          :input,
          carrier_to,
          :ouput
        )
      end

      # Internal: Determines the hour offset a curve should be read from
      #
      # Curves read from the electricity merit order have an offset of 1 for heat
      # networks so that the load for the current hour is based on the electricity
      # load in the previous hour. This is because the electricity loads are
      # calculated *after* the heat network.
      # For hydrogen this offset is not needed.
      def hour_offset
        @context.part_of_heat_network? ? 1 : 0
      end
    end
  end
end
