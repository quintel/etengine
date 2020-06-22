# frozen_string_literal: true

module Qernel
  module MeritFacade
    # An adapter which deals with flexible and storage technologies in the merit
    # order. These technologies store excess for future use, or remove excess
    # via export or curtailment.
    class FlexAdapter < Adapter
      def self.factory(node, context)
        case context.node_config(node).subtype.to_sym
        when :storage
          StorageAdapter
        when :export
          ExportAdapter
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
          participant.output_capacity_per_unit *
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

        attrs[:output_capacity_per_unit] = output_capacity
        attrs[:input_capacity_per_unit] = input_capacity

        attrs
      end

      def input_efficiency
        input = @node.node.input(@context.carrier)
        input ? input.conversion : 0.0
      end

      def output_efficiency
        # Most attributes come from the delegate, but this is not the case for
        # output efficiency for which the participant may be assigned a
        # different value than the delegate.
        output = @node.node.output(@context.carrier)
        output ? output.conversion : 1.0
      end

      def input_capacity
        cap = source_api.input_capacity || source_api.output_capacity
        cap * input_efficiency
      end

      def output_capacity
        cap = source_api.output_capacity || source_api.input_capacity
        cap * output_efficiency
      end

      def producer_class
        Merit::Flex::Base
      end

      def marginal_costs
        @context.dispatchable_sorter.cost(@node, @config)
      end
    end
  end
end
