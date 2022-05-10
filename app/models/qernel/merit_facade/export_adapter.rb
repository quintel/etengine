# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Implements behaviour specific to the export interconnector.
    class ExportAdapter < FlexAdapter
      include OptionalCostCurve
      include OptionalAvailabilityCurve

      def initialize(*)
        super

        unless @context.carrier == :electricity
          raise "#{self.class.name} only supports electricity"
        end
      end

      def installed?
        super && source_api.input_capacity.positive?
      end

      def inject!
        input_edge = target_api.node.input(@context.carrier).edges.first
        demand     = participant.production(:mj)

        target_api.demand = demand

        inject_flh(demand)

        if input_edge.edge_type == :inversed_flexible
          # We need to override the calculation of an inversed flexible edge
          # and set the demand explicitly.
          input_edge.dataset_set(:value, demand)
          input_edge.dataset_set(:calculated, true)
        end

        inject_curve!(:input) do
          @participant.load_curve.map { |v| v.negative? ? v.abs : 0.0 }
        end
      end

      private

      def non_variable_availability_producer_class
        Merit::Flex::Base
      end

      def variable_availability_producer_class
        Merit::Flex::VariableConsumer
      end

      def cost_strategy
        if cost_curve?
          Merit::CostStrategy::FromCurve.new(nil, cost_curve)
        else
          Merit::CostStrategy::Constant.new(nil, marginal_costs)
        end
      end

      # Internal: Creates the attributes for initializing the participant.
      #
      # Not used when the participant is a PriceSensitive.
      def producer_attributes
        attrs = super
        attrs[:output_capacity_per_unit] = 0.0
        attrs[:group] = @config.group
        attrs[:consume_from_dispatchables] = true
        attrs
      end

      def total_input_capacity
        source_api.input_capacity *
          source_api.number_of_units *
          source_api.availability
      end

      def marginal_costs
        source_api.marginal_costs
      end

      def output_capacity
        # Used only when in non-PriceSensitive mode.
        0.0
      end

      def inject_flh(demand)
        capacity = source_api.input_capacity || 0.0
        full_load_seconds = capacity.zero? ? 0.0 : demand / capacity

        target_api[:full_load_hours]   = full_load_seconds / 3600
        target_api[:full_load_seconds] = full_load_seconds
      end
    end
  end
end
