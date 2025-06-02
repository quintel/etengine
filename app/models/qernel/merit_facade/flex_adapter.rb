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
        when :heat_storage
          HeatStorageAdapter
        when :optimizing_storage, :optimizing_storage_households
          OptimizingStorageAdapter
        when :load_shifting
          LoadShiftingAdapter
        when :satisfied_demand
          SatisfiedDemandAdapter
        when :transformation
          TransformationAdapter
        else
          self
        end
      end

      def inject!
        inject_demand!
        inject_costs!

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
        attrs[:consumption_price] = consumption_price

        attrs[:output_capacity_per_unit] = output_capacity
        attrs[:input_capacity_per_unit] = input_capacity

        # We don't ever want heat flex technologies to consume from dispatchables.
        attrs[:consume_from_dispatchables] = !(@context.part_of_heat_network? || @context.hydrogen?)

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
        cap = source_api.input_capacity || total_node_output_capacity
        cap * input_efficiency
      end

      def output_capacity
        cap = total_node_output_capacity || source_api.input_capacity
        cap * output_efficiency
      end

      def total_node_output_capacity
        carrier_specific = source_api.try(@context.carrier_named('%s_output_capacity'))

        if carrier_specific
          carrier_specific / output_efficiency
        else
          source_api.output_capacity
        end
      end

      def producer_class
        Merit::Flex::Base
      end

      def marginal_costs
        @context.dispatchable_sorter.cost(source_api, @config)
      end

      def consumption_price
        @context.flex_demand_sorter&.cost(source_api, @config) || source_api.max_consumption_price
      end

      # Internal: Sets demand and related attributes on the target API.
      def inject_demand!
        full_load_hours = participant.full_load_hours

        full_load_seconds =
          if !full_load_hours || full_load_hours.nan?
            full_load_hours = 0.0
          else
            full_load_hours * 3600
          end

        target_api[:full_load_hours]   = full_load_hours
        target_api[:full_load_seconds] = full_load_seconds

        target_api.demand =
          (full_load_seconds / input_efficiency) *
          participant.input_capacity_per_unit *
          participant.number_of_units
      end

      def inject_costs!
        target_api.dataset_lazy_set(:fuel_costs_electricity) do
          participant.fuel_costs.to_f
        end
      end
    end
  end
end
