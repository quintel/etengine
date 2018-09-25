# frozen_string_literal: true

module Qernel::Plugins
  module Hydrogen
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
        @producer = @converter.input(:electricity).links.first.rgt_converter

        # Capacity needs to be calculated early, as number_of_units requires
        # demand to be present; this varies based on demand.
        @hydrogen_capacity =
          @converter.converter_api.input_capacity *
          @converter.converter_api.hydrogen_output_conversion *
          @converter.converter_api.number_of_units

        # Pre-compute electricity while demand is set on the converter.
        max_available_electricity
      end

      # Public: Capacity-limited demand curve describing the amount of
      # electricity converted to - and output as - hydrogen.
      def demand_curve
        @demand_curve ||= begin
          unlimited_hydrogen_curve.map do |value|
            value < @hydrogen_capacity ? value : @hydrogen_capacity
          end
        end
      end

      def inject!(*)
        super

        return if carrier_demand.zero?

        @converter.demand =
          carrier_demand / @converter.output(:hydrogen).conversion

        @converter[:full_load_hours] =
          carrier_demand / (@hydrogen_capacity * 3600)

        @converter.input(:electricity).links.first.share =
          @converter.demand / max_available_electricity
      end

      private

      # Internal: The maximum amount of electricity available for conversion to
      # hydrogen.
      #
      # Returns a Float.
      def max_available_electricity
        @max_available_electricity ||=
          @producer.demand * @producer.output(:electricity).conversion
      end

      # Internal: The maximum amount of hydrogen which may be emitted by the
      # electrolyser assuming no curtailment and unlimited output capacity.
      #
      # Returns a Float.
      def max_hydrogen_production
        max_available_electricity * @converter.output(:hydrogen).conversion
      end

      # Internal: Curve representing the maximum amount of hydrogen that may be
      # produced in each hour, assuming no electricity is curtailed, and
      # unlimited output capacity of the hydrogen conversion.
      #
      # Returns a Merit::Curve.
      def unlimited_hydrogen_curve
        demand_profile * max_hydrogen_production
      end

      # Internal: Total demand of the hydrogen producer is determined with the
      # capacity-limited demand curve.
      #
      # Returns a Float.
      def calculate_carrier_demand
        demand_curve.sum * 3600
      end
    end
  end
end
