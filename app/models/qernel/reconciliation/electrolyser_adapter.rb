# frozen_string_literal: true

module Qernel
  module Reconciliation
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
    class ElectrolyserAdapter < ProducerAdapter
      def initialize(*)
        super
        @producer = @node.input(:electricity).links.first.rgt_node

        output_conversion_name = @context.carrier_named('%s_output_conversion')

        # Capacity needs to be calculated early, as number_of_units requires
        # demand to be present; this varies based on demand.
        @carrier_capacity =
          @node.node_api.input_capacity *
          @node.node_api.public_send(output_conversion_name) *
          @node.node_api.number_of_units

        # Pre-compute electricity while demand is set on the node.
        max_available_electricity
      end

      # Public: Capacity-limited demand curve describing the amount of
      # electricity converted to - and output as - carrier energy.
      def demand_curve
        @demand_curve ||= begin
          unlimited_carrier_curve.map do |value|
            value < @carrier_capacity ? value : @carrier_capacity
          end
        end
      end

      def inject!(*)
        super

        return if carrier_demand.zero?

        @node.demand =
          carrier_demand / @node.output(@context.carrier).conversion

        @node[:full_load_hours] =
          carrier_demand / (@carrier_capacity * 3600)

        electricity_h2_share = @node.demand / max_available_electricity

        # Set share explicitly to 1.0 when the producer -> electrolyser share is
        # very close to 1.0 (floating point errors).
        @node.input(:electricity).links.first.share =
          (1 - electricity_h2_share).abs < 1e-4 ? 1.0 : electricity_h2_share
      end

      private

      # Internal: The maximum amount of electricity available for conversion to
      # the carrier.
      #
      # Returns a Float.
      def max_available_electricity
        @max_available_electricity ||=
          @producer.demand * @producer.output(:electricity).conversion
      end

      # Internal: The maximum amount of carrier energy which may be emitted by
      # the electrolyser assuming no curtailment and unlimited output capacity.
      #
      # Returns a Float.
      def max_carrier_production
        max_available_electricity * @node.output(@context.carrier).conversion
      end

      # Internal: Curve representing the maximum amount of carrier energy that
      # may be produced in each hour, assuming no electricity is curtailed, and
      # unlimited output capacity of the carrier conversion.
      #
      # Returns a Merit::Curve.
      def unlimited_carrier_curve
        demand_profile * max_carrier_production
      end

      # Internal: The total demand of the producer is determined with the
      # capacity-limited demand curve.
      #
      # Returns a Float.
      def calculate_carrier_demand
        demand_curve.sum * 3600
      end

      # Internal: Amplified dynamic profiles must use the electricity producer
      # FLH, as the electrolyser FLH may not be correct prior to calculating.
      #
      # Returns a numeric.
      def full_load_hours
        @producer.node_api.full_load_hours
      end
    end
  end
end
