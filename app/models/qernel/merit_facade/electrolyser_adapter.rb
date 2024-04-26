# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Electrolysers are a special-case producer whose load profile is based on
    # the electricity output by another node.
    #
    # The electricity node is expected to be the only input to the electrolyser,
    # and will have a second electricity output to a curtailment node.
    #
    #   [ Electrolyser ]  <-
    #                         [ Electricity Producer ]
    #   [ Curtailment ]  <--
    #
    # The load profile is based on the electricity profile of the input
    # producer, limited by the efficiency and capacity of the electrolyser. From
    # the resulting profile, the demand and full load hours can be calculated,
    # and the share of curtailment updated.
    class ElectrolyserAdapter < CurtailedAlwaysOnAdapter
      def initialize(*)
        super

        @producer_node = @node.input(:electricity).edges.first.rgt_node

        # Capacity needs to be calculated early, as number_of_units requires
        # demand to be present; this varies based on demand.
        @carrier_capacity =
          output_capacity_per_unit *
          @node.number_of_units

        @input_cap = @node.input_capacity * @node.number_of_units

        # Pre-compute electricity while demand is set on the node.
        max_available_electricity
      end

      private

      def install_demand!
        super

        # TODO: check for FLH with Mathijs
        target_api[:full_load_hours] =
          @participant.production(:mj) / (@carrier_capacity * 3600)

        return if max_available_electricity.zero?

        electricity_h2_share = target_api.demand / max_available_electricity

        # Set share explicitly to 1.0 when the producer -> electrolyser share is
        # very close to 1.0 (floating point errors).
        target_api.input(:electricity).edges.first.share =
          (1 - electricity_h2_share).abs < 1e-4 ? 1.0 : electricity_h2_share
      end

      def producer_class
        Merit::VolatileProducer
      end

      def production_profile
        profile = profile_builder.useable_profile
        new_sum = profile.sum

        # Normalize to get the curve representable again.
        profile.class.new(profile.map { |val| val / (new_sum * 3600.0) })
      end

      # Internal: Creates a class which will create the useable profile for the
      # participant, accounting for curtailment.
      #
      # The share of curtailment is calculated on the bases of the capacity needed
      # to handle the output of the e-producer of the electrolyser, and the capacity
      # of the electrolyser itself.
      def profile_builder
        @profile_builder ||=
          begin
            max_capacity_from_curve = unlimited_input_curve_max

            curtailment = if max_capacity_from_curve.zero? || @input_cap > max_capacity_from_curve
              0.0
            else
              (max_capacity_from_curve - @input_cap) / max_capacity_from_curve
            end

            if curtailment.positive? && @config.group.to_s.starts_with?('self:')
              raise 'Cannot use non-zero production_curtailment with a ' \
                    "\"self:...\" curve in #{@node.key}"
            end

            CurtailedProfile.new(
              @context.curves.curve(@config.group, @node),
              curtailment
            )
          end
      end

      # Internal: maximum of a curve representing the maximum amount of electricity energy that
      # may be input in each hour, assuming no electricity is curtailed, and
      # unlimited input capacity.
      #
      # Returns a Float
      def unlimited_input_curve_max
        @context.curves.curve(@config.group, @node).max * max_available_electricity
      end

      # Internal: The maximum amount of electricity available for conversion to
      # the carrier.
      #
      # Returns a Float.
      def max_available_electricity
        @max_available_electricity ||=
          @producer_node.demand * @producer_node.output(:electricity).conversion
      end
    end
  end
end
