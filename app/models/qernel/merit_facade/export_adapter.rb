# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Implements behaviour specific to the export interconnector.
    class ExportAdapter < FlexAdapter
      include OptionalCostCurve

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
        input_link = target_api.node.input(@context.carrier).links.first
        demand     = participant.production(:mj)

        target_api.demand = demand

        inject_flh(demand)

        if input_link.link_type == :inversed_flexible
          # We need to override the calculation of an inversed flexible link
          # and set the demand explicitly.
          input_link.dataset_set(:value, demand)
          input_link.dataset_set(:calculated, true)
        end

        if @config.satisfy_with_dispatchables
          inject_curve!(:input) { @participant.load_curve }
        else
          inject_curve!(:input) do
            @participant.load_curve.map { |v| v.negative? ? v.abs : 0.0 }
          end
        end
      end

      def participant
        # Export is price-sensitive. An IC wants to export at full capacity all
        # the time, but only if it is cost-effective to do so.
        @participant ||=
          if @config.satisfy_with_dispatchables
            Merit::User::PriceSensitive.new(
              inner_consumer,
              cost_strategy,
              @config.group
            )
          else
            Merit::Flex::Base.new(producer_attributes)
          end
      end

      private

      def cost_strategy
        if cost_curve?
          Merit::CostStrategy::FromCurve.new(nil, cost_curve)
        else
          Merit::CostStrategy::Constant.new(nil, marginal_costs)
        end
      end

      def inner_consumer
        @inner_consumer ||= Merit::User.create(
          key: source_api.key,
          load_curve: Merit::Curve.new([total_input_capacity] * Merit::POINTS)
        )
      end

      # Internal: Creates the attributes for initializing the participant.
      #
      # Not used when the participant is a PriceSensitive.
      def producer_attributes
        attrs = super
        attrs[:group] = @config.group
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
