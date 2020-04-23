# frozen_string_literal: true

module Qernel
  module MeritFacade
    # An adapter which deals with flexible and storage technologies in the merit
    # order. These technologies store excess for future use, or remove excess
    # via export or curtailment.
    class FlexAdapter < Adapter
      def self.factory(converter, context)
        case context.node_config(converter).subtype.to_sym
        when :storage
          StorageAdapter
        when :power_to_gas
          PowerToGasAdapter
        when :power_to_heat_industry
          PowerToHeatAdapter
        when :power_to_heat
          HouseholdPowerToHeatAdapter
        when :curtailment
          CurtailmentAdapter
        else
          self
        end
      end

      def inject!
        full_load_hours = participant.full_load_hours / input_efficiency

        full_load_seconds =
          if !full_load_hours || full_load_hours.nan?
            full_load_hours = 0.0
          else
            full_load_hours * 3600
          end

        target_api[:full_load_hours]   = full_load_hours
        target_api[:full_load_seconds] = full_load_seconds

        target_api.demand =
          full_load_seconds *
          source_api.input_capacity *
          participant.number_of_units

        inject_curve!(:input) do
          @participant.load_curve.map { |v| v.negative? ? v.abs : 0.0 }
        end

        inject_curve!(:output) do
          @participant.load_curve.map { |v| v.positive? ? v : 0.0 }
        end
      end

      private

      def producer_attributes
        attrs = super

        attrs[:marginal_costs] = marginal_costs

        # Default is to multiply the input capacity by the carrier output
        # conversion. This doesn't work, because the flex converters have a
        # dependant link and the conversion will be zero the first time the
        # graph is calculated.
        attrs[:output_capacity_per_unit] =
          source_api.output_capacity ||
          source_api.input_capacity

        attrs
      end

      def input_efficiency
        @converter.converter.input(@context.carrier)&.conversion || 1.0
      end

      def output_efficiency
        # Most attributes come from the delegate, but this is not the case for
        # output efficiency for which the participant may be assigned a
        # different value than the delegate.
        slots = @converter.converter.outputs.reject(&:loss?)
        slots.any? ? slots.sum(&:conversion) : 1.0
      end

      def producer_class
        Merit::Flex::Base
      end

      def marginal_costs
        @context.dispatchable_sorter.cost(@converter, @config)
      end
    end
  end
end
